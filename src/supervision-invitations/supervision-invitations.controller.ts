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
import { DoctorOnlyGuard } from '../auth/guards/doctor-only.guard';
import { StudentOnlyGuard } from '../auth/guards/student-only.guard';
import { SendSupervisionInvitesDto } from './dto/send-supervision-invites.dto';
import { SupervisionInvitationsService } from './supervision-invitations.service';

@Controller('supervision-invitations')
@UseGuards(AuthGuard('jwt'))
export class SupervisionInvitationsController {
  constructor(private readonly svc: SupervisionInvitationsService) {}

  @Post()
  @UseGuards(StudentOnlyGuard)
  send(
    @CurrentUser() user: JwtPayload,
    @Body() dto: SendSupervisionInvitesDto,
  ) {
    return this.svc.send(user.sub, dto);
  }

  @Get('me/outgoing')
  @UseGuards(StudentOnlyGuard)
  outgoing(@CurrentUser() user: JwtPayload) {
    return this.svc.listOutgoing(user.sub);
  }

  @Get('doctor/pending')
  @UseGuards(DoctorOnlyGuard)
  pendingForDoctor(@CurrentUser() user: JwtPayload) {
    return this.svc.listPendingForDoctor(user.sub);
  }

  @Patch('doctor/:id/accept')
  @UseGuards(DoctorOnlyGuard)
  accept(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.svc.acceptByDoctor(user.sub, id);
  }

  @Patch('doctor/:id/reject')
  @UseGuards(DoctorOnlyGuard)
  reject(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.svc.rejectByDoctor(user.sub, id);
  }
}
