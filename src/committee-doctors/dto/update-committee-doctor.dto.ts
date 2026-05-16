import { PartialType } from '@nestjs/mapped-types';
import { CreateCommitteeDoctorDto } from './create-committee-doctor.dto';

export class UpdateCommitteeDoctorDto extends PartialType(
  CreateCommitteeDoctorDto,
) {}
