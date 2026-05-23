import {
  Body,
  Controller,
  Get,
  HttpException,
  HttpStatus,
  Logger,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

import { extractModelNames } from './extract-model-names';

export type AiChatBody = {
  query: string;
  conversation_history?: string;
  conversationHistory?: string;
  model?: string;
};

export type AiSearchRequest = {
  query: string;
  k?: number;
};
const DEFAULT_MODEL = 'qwen2.5:7b';
const DEFAULT_CHAT_TIMEOUT_MS = Number(
  process.env.AI_CHAT_TIMEOUT_MS ?? 330_000,
); /* ~5.5 min بينما يولِّد النموذج */

function aiServiceBase(): string {
  return (
    process.env.AI_SERVICE_URL?.replace(/\/$/, '') ?? 'http://127.0.0.1:8000'
  );
}

function ollamaTagsBase(): string {
  const raw =
    process.env.OLLAMA_URL?.replace(/\/$/, '') ?? 'http://127.0.0.1:11434';
  return raw.replace(/\/api\/?$/i, '');
}

function uniqStrings(items: string[]): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const s of items) {
    const t = String(s).trim();
    if (t.length === 0 || seen.has(t)) {
      continue;
    }
    seen.add(t);
    out.push(t);
  }
  return out;
}

@Controller('integrations/ai')
@UseGuards(AuthGuard('jwt'))
export class AiChatProxyController {
  private readonly logger = new Logger(AiChatProxyController.name);

  constructor(private readonly http: HttpService) {}

  /**
   * يجلب أسماء النماذج: أولاً `GET {AI_SERVICE_URL}/api/models`، وإلا `GET /api/tags` على Ollama.
   */
  @Get('models')
  async listModels(): Promise<{ models: string[] }> {
    for (const attempt of ['/api/models', '/models']) {
      try {
        const url = `${aiServiceBase()}${attempt}`;
        const { data } = await firstValueFrom(
          this.http.get<unknown>(url, { timeout: 15_000 }),
        );
        const parsed = uniqStrings(extractModelNames(data));
        if (parsed.length > 0) {
          return { models: parsed };
        }
      } catch {
        /* جرّب المسار التالي أو انتقل إلى Ollama */
      }
    }

    try {
      const { data } = await firstValueFrom(
        this.http.get<{ models?: { name?: string }[] }>(
          `${ollamaTagsBase()}/api/tags`,
          { timeout: 15_000 },
        ),
      );
      const names =
        data?.models?.map((m) => m?.name).filter(Boolean) ?? [];
      if (names.length > 0) {
        return { models: uniqStrings(names as string[]) };
      }
    } catch (err: unknown) {
      this.logger.debug(`ollama tags skip: ${String(err)}`);
    }

    return { models: [DEFAULT_MODEL] };
  }

  /**
   * Proxies to Python FastAPI (`generative_projects` / Ollama) so Flutter
   * only talks to Nest (one base URL, CORS, future auth).
   */
  @Post('chat')
  async chat(@Body() body: AiChatBody) {
    const query = body?.query?.trim();
    if (!query) {
      throw new HttpException('query is required', HttpStatus.BAD_REQUEST);
    }

    const base = aiServiceBase();
    const conversationHistory =
      body.conversation_history ?? body.conversationHistory ?? '';

    try {
      const { data } = await firstValueFrom(
        this.http.post<{ message: string }>(
          `${base}/api/chat`,
          {
            query,
            conversation_history: conversationHistory,
            model: body.model?.trim() || DEFAULT_MODEL,
          },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: DEFAULT_CHAT_TIMEOUT_MS,
          },
        ),
      );
      return data;
    } catch (err: unknown) {
      this.logger.warn(`AI proxy failed: ${String(err)}`);
      throw new HttpException(
        'تعذر الاتصال بخدمة الذكاء الاصطناعي. تأكد من تشغيل FastAPI وOllama.',
        HttpStatus.BAD_GATEWAY,
      );
    }
  }


  @Post('search')
  async search(@Body() body: AiSearchRequest) {
    const query = body?.query?.trim();
    if (!query) {
      throw new HttpException('query is required', HttpStatus.BAD_REQUEST);
    }

    const base = aiServiceBase();
    const payload: { query: string; k?: number } = { query };
    if (typeof body?.k === 'number' && Number.isFinite(body.k)) {
      payload.k = Math.min(10, Math.max(1, Math.floor(body.k)));
    }

    try {
      const { data } = await firstValueFrom(
        this.http.post<{
          query?: string;
          count?: number;
          results?: unknown[];
        }>(`${base}/api/search`, payload, {
          headers: { 'Content-Type': 'application/json' },
          timeout: Math.min(DEFAULT_CHAT_TIMEOUT_MS, 120_000),
        }),
      );
      return data;
    } catch (err: unknown) {
      this.logger.warn(`AI proxy failed: ${String(err)}`);
      throw new HttpException(
        'تعذر الاتصال بخدمة الذكاء الاصطناعي. تأكد من تشغيل FastAPI وOllama.',
        HttpStatus.BAD_GATEWAY,
      );
    }
  }
}
