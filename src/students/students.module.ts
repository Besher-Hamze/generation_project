import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { StudentsController } from './students.controller';
import { StudentsService } from './students.service';

@Module({
  imports: [SchemasModule],
  controllers: [StudentsController],
  providers: [StudentsService, AdminOnlyGuard],
})
export class StudentsModule {}
