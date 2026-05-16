import {
  Body,
  Controller,
  Delete,
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
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';
import { SessionsService } from './sessions.service';

@Controller('sessions')
@UseGuards(AuthGuard('jwt'))
export class SessionsController {
  constructor(private readonly svc: SessionsService) {}

  @Get('me')
  findMine(@CurrentUser() user: JwtPayload) {
    return this.svc.findForCurrentUser(user);
  }

  @Get(':id')
  findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.findOneVisible(user, id);
  }

  @Post()
  @UseGuards(DoctorOnlyGuard)
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateSessionDto) {
    return this.svc.createForActor(user, dto);
  }

  @Patch(':id')
  @UseGuards(DoctorOnlyGuard)
  update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateSessionDto,
  ) {
    return this.svc.updateForActor(user, id, dto);
  }

  @Delete(':id')
  @UseGuards(DoctorOnlyGuard)
  remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.svc.removeForActor(user, id);
  }
}
