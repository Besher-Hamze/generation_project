import { Module } from '@nestjs/common';
import { SchemasModule } from '../schemas/schemas.module';
import { PublicController } from './public.controller';

@Module({
  imports: [SchemasModule],
  controllers: [PublicController],
})
export class PublicModule {}
