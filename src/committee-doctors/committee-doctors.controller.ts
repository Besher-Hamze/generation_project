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
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { CommitteeDoctorsService } from './committee-doctors.service';
import { CreateCommitteeDoctorDto } from './dto/create-committee-doctor.dto';
import { UpdateCommitteeDoctorDto } from './dto/update-committee-doctor.dto';

@Controller('committee-doctors')
@UseGuards(AuthGuard('jwt'))
export class CommitteeDoctorsController {
  constructor(private readonly svc: CommitteeDoctorsService) {}

  @Post()
  @UseGuards(AdminOnlyGuard)
  create(@Body() dto: CreateCommitteeDoctorDto) {
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

  @Patch(':id')
  @UseGuards(AdminOnlyGuard)
  update(@Param('id') id: string, @Body() dto: UpdateCommitteeDoctorDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminOnlyGuard)
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
