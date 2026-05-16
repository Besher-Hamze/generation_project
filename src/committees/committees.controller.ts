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
import { CommitteesService } from './committees.service';
import { CreateCommitteesDto } from './dto/create-committees.dto';
import { UpdateCommitteesDto } from './dto/update-committees.dto';

@Controller('committees')
@UseGuards(AuthGuard('jwt'))
export class CommitteesController {
  constructor(private readonly svc: CommitteesService) {}

  @Post()
  @UseGuards(AdminOnlyGuard)
  create(@Body() dto: CreateCommitteesDto) {
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
  update(@Param('id') id: string, @Body() dto: UpdateCommitteesDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AdminOnlyGuard)
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
