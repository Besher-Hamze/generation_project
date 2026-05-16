import { Module } from '@nestjs/common';
import { AdminOnlyGuard } from '../auth/guards/admin-only.guard';
import { SchemasModule } from '../schemas/schemas.module';
import { RegistrationOrdersController } from './registration-orders.controller';
import { RegistrationOrdersService } from './registration-orders.service';

@Module({
  imports: [SchemasModule],
  controllers: [RegistrationOrdersController],
  providers: [RegistrationOrdersService, AdminOnlyGuard],
})
export class RegistrationOrdersModule {}
