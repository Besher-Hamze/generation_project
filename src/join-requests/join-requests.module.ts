import { Module } from '@nestjs/common';
import { SchemasModule } from '../schemas/schemas.module';
import { DoctorOnlyGuard } from '../auth/guards/doctor-only.guard';
import { StudentOnlyGuard } from '../auth/guards/student-only.guard';
import { JoinRequestsController } from './join-requests.controller';
import { JoinRequestsService } from './join-requests.service';
import { JoinRequestsRepository } from './repositories/join-requests.repository';

@Module({
  imports: [SchemasModule],
  controllers: [JoinRequestsController],
  providers: [
    JoinRequestsRepository,
    JoinRequestsService,
    StudentOnlyGuard,
    DoctorOnlyGuard,
  ],
})
export class JoinRequestsModule {}
