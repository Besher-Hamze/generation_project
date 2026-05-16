import { Module } from '@nestjs/common';
import { SchemasModule } from '../schemas/schemas.module';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SystemSettingsController } from './system-settings.controller';
import { SystemSettingsService } from './system-settings.service';

@Module({
  imports: [SchemasModule],
  controllers: [SystemSettingsController],
  providers: [SystemSettingsService, AdminOnlyGuard],
})
export class SystemSettingsModule {}
