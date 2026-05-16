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
import { DepartmentsService } from './departments.service';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@Controller('departments')
@UseGuards(AuthGuard('jwt'))
export class DepartmentsController {
  constructor(private readonly svc: DepartmentsService) {}

  @Post()
  @UseGuards(AdminOnlyGuard)
  create(@Body() dto: CreateDepartmentDto) {
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
  update(@Param('id') id: string, @Body() dto: UpdateDepartmentDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminOnlyGuard)
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
