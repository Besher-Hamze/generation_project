import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { DoctorsController } from './doctors.controller';
import { DoctorsService } from './doctors.service';

@Module({
  imports: [SchemasModule],
  controllers: [DoctorsController],
  providers: [DoctorsService, AdminOnlyGuard],
})
export class DoctorsModule {}
