import { Module } from '@nestjs/common';
import { SchemasModule } from '../schemas/schemas.module';
import { DoctorOnlyGuard } from '../auth/guards/doctor-only.guard';
import { SessionsController } from './sessions.controller';
import { SessionsRepository } from './repositories/sessions.repository';
import { SessionsService } from './sessions.service';

@Module({
  imports: [SchemasModule],
  controllers: [SessionsController],
  providers: [SessionsRepository, SessionsService, DoctorOnlyGuard],
})
export class SessionsModule {}
