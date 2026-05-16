import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { CommitteesController } from './committees.controller';
import { CommitteesService } from './committees.service';

@Module({
  imports: [SchemasModule],
  controllers: [CommitteesController],
  providers: [CommitteesService, AdminOnlyGuard],
})
export class CommitteesModule {}
