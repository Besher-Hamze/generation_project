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
import { CreateRegistrationOrderDto } from './dto/create-registration-order.dto';
import { UpdateRegistrationOrderDto } from './dto/update-registration-order.dto';
import { RegistrationOrdersService } from './registration-orders.service';

@Controller('registration-orders')
@UseGuards(AuthGuard('jwt'))
export class RegistrationOrdersController {
  constructor(private readonly svc: RegistrationOrdersService) {}

  @Post()
  @UseGuards(AdminOnlyGuard)
  create(@Body() dto: CreateRegistrationOrderDto) {
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
  update(@Param('id') id: string, @Body() dto: UpdateRegistrationOrderDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminOnlyGuard)
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
