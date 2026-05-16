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
import { SystemSettingsService } from './system-settings.service';

@Controller('system-settings')
@UseGuards(AuthGuard('jwt'), AdminOnlyGuard)
export class SystemSettingsController {
  constructor(private readonly svc: SystemSettingsService) {}

  @Post()
  upsert(
    @Body() body: { key: string; value: string; description?: string },
  ) {
    return this.svc.upsert(body.key, body.value, body.description);
  }

  @Get()
  findAll() {
    return this.svc.findAll();
  }

  @Get(':key')
  findOne(@Param('key') key: string) {
    return this.svc.findByKey(key);
  }

  @Patch(':key')
  update(@Param('key') key: string, @Body() body: { value: string }) {
    return this.svc.updateValue(key, body.value);
  }

  @Delete(':key')
  remove(@Param('key') key: string) {
    return this.svc.remove(key);
  }
}
