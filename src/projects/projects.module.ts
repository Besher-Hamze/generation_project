import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { DoctorOnlyGuard } from '../auth/guards/doctor-only.guard';
import { StudentOnlyGuard } from '../auth/guards/student-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { ProjectsController } from './projects.controller';
import { ProjectsService } from './projects.service';

@Module({
  imports: [SchemasModule],
  controllers: [ProjectsController],
  providers: [
    ProjectsService,
    StudentOnlyGuard,
    AdminOnlyGuard,
    DoctorOnlyGuard,
  ],
})
export class ProjectsModule {}
