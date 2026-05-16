import { Module } from '@nestjs/common';
import { SchemasModule } from '../schemas/schemas.module';
import { StudentOnlyGuard } from '../auth/guards/student-only.guard';
import { PeerTeamJoinRequestsController } from './peer-team-join-requests.controller';
import { PeerTeamJoinRequestsService } from './peer-team-join-requests.service';

@Module({
  imports: [SchemasModule],
  controllers: [PeerTeamJoinRequestsController],
  providers: [PeerTeamJoinRequestsService, StudentOnlyGuard],
})
export class PeerTeamJoinRequestsModule {}
