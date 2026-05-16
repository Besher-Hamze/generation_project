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
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { DoctorOnlyGuard } from '../auth/guards/doctor-only.guard';
import { StudentOnlyGuard } from '../auth/guards/student-only.guard';
import { CreateProjectDto } from './dto/create-project.dto';
import { DefenseFinalMarkDto } from './dto/defense-final-mark.dto';
import { StudentCreateProjectDto } from './dto/student-create-project.dto';
import { StudentUpdateOwnProjectDto } from './dto/student-update-own-project.dto';
import { TeamEnrollmentSettingsDto } from './dto/team-enrollment-settings.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { ProjectsService } from './projects.service';

@Controller('projects')
@UseGuards(AuthGuard('jwt'))
export class ProjectsController {
  constructor(private readonly svc: ProjectsService) {}

  /** إنشاء مشروع من قبل الطالب (UML). يجب أن يكون غير مسجّل بطريق مشروع بعد. */
  @Post('mine')
  @UseGuards(StudentOnlyGuard)
  createMine(
    @CurrentUser() user: JwtPayload,
    @Body() dto: StudentCreateProjectDto,
  ) {
    return this.svc.createMine(user.sub, dto);
  }

  @Patch('mine/:projectId/team-enrollment')
  @UseGuards(StudentOnlyGuard)
  updateMyTeamEnrollment(
    @CurrentUser() user: JwtPayload,
    @Param('projectId') projectId: string,
    @Body() dto: TeamEnrollmentSettingsDto,
  ) {
    return this.svc.updateTeamEnrollmentForOwner(user.sub, projectId, dto);
  }

  @Patch('mine/:projectId')
  @UseGuards(StudentOnlyGuard)
  updateMyProjectContent(
    @CurrentUser() user: JwtPayload,
    @Param('projectId') projectId: string,
    @Body() dto: StudentUpdateOwnProjectDto,
  ) {
    return this.svc.updateMineContent(user.sub, projectId, dto);
  }

  @Delete('mine/:projectId')
  @UseGuards(StudentOnlyGuard)
  deleteMyProject(
    @CurrentUser() user: JwtPayload,
    @Param('projectId') projectId: string,
  ) {
    return this.svc.deleteMineProject(user.sub, projectId);
  }

  /** تعريف كامل لمشروع (مشرف النظام / سيناريوهات أكاديمية). */
  @Post()
  @UseGuards(AdminOnlyGuard)
  create(@Body() dto: CreateProjectDto) {
    return this.svc.create(dto);
  }

  @Get()
  findAll() {
    return this.svc.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  /** عضو اللجنة: علامة نهائية بعد المناقشة (بحسب لجنة جُمِّعت للمشروع من الإدارة). */
  @Patch(':id/defense-final-mark')
  @UseGuards(DoctorOnlyGuard)
  defenseFinalMark(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: DefenseFinalMarkDto,
  ) {
    return this.svc.setDefenseFinalMark(user.sub, id, dto);
  }

  @Patch(':id')
  @UseGuards(AdminOnlyGuard)
  update(@Param('id') id: string, @Body() dto: UpdateProjectDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminOnlyGuard)
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
