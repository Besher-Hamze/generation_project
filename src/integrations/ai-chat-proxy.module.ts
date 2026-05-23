import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { AiChatProxyController } from './ai-chat-proxy.controller';

@Module({
  imports: [
    HttpModule.register({
      timeout: Math.max(
        Number(process.env.AI_CHAT_TIMEOUT_MS ?? 330_000),
        330_000,
      ),
      maxRedirects: 3,
    }),
  ],
  controllers: [AiChatProxyController],
})
export class AiChatProxyModule {}
