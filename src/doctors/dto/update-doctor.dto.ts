import { PartialType, OmitType } from '@nestjs/mapped-types';
import { IsOptional, IsString, MinLength } from 'class-validator';
import { CreateDoctorDto } from './create-doctor.dto';

export class UpdateDoctorDto extends PartialType(
  OmitType(CreateDoctorDto, ['password'] as const),
) {
  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;
}
