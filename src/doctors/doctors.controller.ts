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
import { CreateDoctorDto } from './dto/create-doctor.dto';
import { UpdateDoctorDto } from './dto/update-doctor.dto';
import { DoctorsService } from './doctors.service';

@Controller('doctors')
@UseGuards(AuthGuard('jwt'))
export class DoctorsController {
  constructor(private readonly svc: DoctorsService) {}

  @Post()
  @UseGuards(AdminOnlyGuard)
  create(@Body() dto: CreateDoctorDto) {
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
  update(@Param('id') id: string, @Body() dto: UpdateDoctorDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminOnlyGuard)
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
