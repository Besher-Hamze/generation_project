import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { BlacklistsController } from './blacklists.controller';
import { BlacklistsService } from './blacklists.service';

@Module({
  imports: [SchemasModule],
  controllers: [BlacklistsController],
  providers: [BlacklistsService, AdminOnlyGuard],
})
export class BlacklistsModule {}
