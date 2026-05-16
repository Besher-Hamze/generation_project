import { PartialType } from '@nestjs/mapped-types';
import { CreateRegistrationOrderDto } from './create-registration-order.dto';

export class UpdateRegistrationOrderDto extends PartialType(
  CreateRegistrationOrderDto,
) {}
