import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { CommitteeDoctorsController } from './committee-doctors.controller';
import { CommitteeDoctorsService } from './committee-doctors.service';

@Module({
  imports: [SchemasModule],
  controllers: [CommitteeDoctorsController],
  providers: [CommitteeDoctorsService, AdminOnlyGuard],
})
export class CommitteeDoctorsModule {}
