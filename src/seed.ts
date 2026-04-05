import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { SeedModule } from './seed/seed.module';
import { SeedService } from './seed/seed.service';

async function bootstrap() {
  const logger = new Logger('Seed');
  const app = await NestFactory.createApplicationContext(SeedModule, {
    logger: ['error', 'warn', 'log'],
  });
  try {
    const csvArg = process.argv.find((a) => a.startsWith('--csv='));
    const csvPath = csvArg ? csvArg.slice('--csv='.length) : undefined;
    const seed = app.get(SeedService);
    const result = await seed.run(csvPath);
    logger.log(JSON.stringify(result));
  } finally {
    await app.close();
  }
}

void bootstrap();
