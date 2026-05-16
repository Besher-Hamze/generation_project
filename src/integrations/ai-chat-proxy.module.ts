import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';
import { AiChatProxyController } from './ai-chat-proxy.controller';

@Module({
  imports: [
    HttpModule.register({
      timeout: Number(process.env.AI_CHAT_TIMEOUT_MS ?? 120_000),
      maxRedirects: 3,
    }),
  ],
  controllers: [AiChatProxyController],
})
export class AiChatProxyModule {}
