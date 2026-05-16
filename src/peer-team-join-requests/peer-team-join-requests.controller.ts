import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import type { JwtPayload } from '../auth/jwt.strategy';
import { CurrentUser } from '../auth/current-user.decorator';
import { StudentOnlyGuard } from '../auth/guards/student-only.guard';
import { CreatePeerTeamJoinDto } from './dto/create-peer-team-join.dto';
import { PeerTeamJoinRequestsService } from './peer-team-join-requests.service';

@Controller('peer-team-requests')
@UseGuards(AuthGuard('jwt'))
export class PeerTeamJoinRequestsController {
  constructor(private readonly svc: PeerTeamJoinRequestsService) {}

  @Post()
  @UseGuards(StudentOnlyGuard)
  create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreatePeerTeamJoinDto,
  ) {
    return this.svc.create(user.sub, dto);
  }

  @Get('me/outgoing')
  @UseGuards(StudentOnlyGuard)
  outgoing(@CurrentUser() user: JwtPayload) {
    return this.svc.listOutgoing(user.sub);
  }

  @Get('me/incoming')
  @UseGuards(StudentOnlyGuard)
  incoming(@CurrentUser() user: JwtPayload) {
    return this.svc.listIncoming(user.sub);
  }

  @Patch(':id/owner-approve')
  @UseGuards(StudentOnlyGuard)
  ownerApprove(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.svc.approve(user.sub, id);
  }

  @Patch(':id/owner-reject')
  @UseGuards(StudentOnlyGuard)
  ownerReject(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.svc.reject(user.sub, id);
  }
}
