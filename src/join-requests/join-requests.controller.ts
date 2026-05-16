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
import { CreateJoinRequestDto } from './dto/create-join-request.dto';
import { JoinRequestsService } from './join-requests.service';

@Controller('join-requests')
@UseGuards(AuthGuard('jwt'))
export class JoinRequestsController {
  constructor(private readonly joinRequests: JoinRequestsService) {}

  @Post()
  @UseGuards(StudentOnlyGuard)
  create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateJoinRequestDto,
  ) {
    return this.joinRequests.create(user.sub, dto);
  }

  @Get('me/outgoing')
  @UseGuards(StudentOnlyGuard)
  outgoing(@CurrentUser() user: JwtPayload) {
    return this.joinRequests.listOutgoing(user.sub);
  }

  @Get('doctor/pending')
  @UseGuards(DoctorOnlyGuard)
  pendingForDoctor(@CurrentUser() user: JwtPayload) {
    return this.joinRequests.listPendingForDoctor(user.sub);
  }

  @Patch('doctor/:id/approve')
  @UseGuards(DoctorOnlyGuard)
  approveByDoctor(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.joinRequests.approveByDoctor(id, user.sub);
  }

  @Patch('doctor/:id/reject')
  @UseGuards(DoctorOnlyGuard)
  rejectByDoctor(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.joinRequests.rejectByDoctor(id, user.sub);
  }
}
