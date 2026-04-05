import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { SchemasModule } from '../schemas/schemas.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        uri:
          config.get<string>('MONGODB_URI') ??
          'mongodb://127.0.0.1:27017/generation_project',
      }),
      inject: [ConfigService],
    }),
    SchemasModule,
  ],
  exports: [MongooseModule, SchemasModule],
})
export class DatabaseModule {}
