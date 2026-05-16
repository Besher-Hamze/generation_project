import { PartialType, OmitType } from '@nestjs/mapped-types';
import { IsOptional, IsString, MinLength } from 'class-validator';
import { CreateStudentDto } from './create-student.dto';

export class UpdateStudentDto extends PartialType(
  OmitType(CreateStudentDto, ['password'] as const),
) {
  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;
}
