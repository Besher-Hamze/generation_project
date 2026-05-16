import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { DepartmentsController } from './departments.controller';
import { DepartmentsService } from './departments.service';

@Module({
  imports: [SchemasModule],
  controllers: [DepartmentsController],
  providers: [DepartmentsService, AdminOnlyGuard],
})
export class DepartmentsModule {}
