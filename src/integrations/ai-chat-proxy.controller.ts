import {
  Body,
  Controller,
  HttpException,
  HttpStatus,
  Logger,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

export type AiChatBody = {
  query: string;
  conversation_history?: string;
  conversationHistory?: string;
  model?: string;
};

@Controller('integrations/ai')
@UseGuards(AuthGuard('jwt'))
export class AiChatProxyController {
  private readonly logger = new Logger(AiChatProxyController.name);

  constructor(private readonly http: HttpService) {}

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

    const base =
      process.env.AI_SERVICE_URL?.replace(/\/$/, '') ??
      'http://127.0.0.1:8000';
    const conversationHistory =
      body.conversation_history ?? body.conversationHistory ?? '';

    try {
      const { data } = await firstValueFrom(
        this.http.post<{ message: string }>(
          `${base}/api/chat`,
          {
            query,
            conversation_history: conversationHistory,
            model: body.model ?? 'qwen2.5:7b',
          },
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: Number(process.env.AI_CHAT_TIMEOUT_MS ?? 120_000),
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
}
