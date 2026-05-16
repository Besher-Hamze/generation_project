import { Module } from '@nestjs/common';
import { SchemasModule } from '../schemas/schemas.module';
import { DoctorOnlyGuard } from '../auth/guards/doctor-only.guard';
import { StudentOnlyGuard } from '../auth/guards/student-only.guard';
import { SupervisionInvitationsController } from './supervision-invitations.controller';
import { SupervisionInvitationsService } from './supervision-invitations.service';

@Module({
  imports: [SchemasModule],
  controllers: [SupervisionInvitationsController],
  providers: [
    SupervisionInvitationsService,
    StudentOnlyGuard,
    DoctorOnlyGuard,
  ],
})
export class SupervisionInvitationsModule {}
