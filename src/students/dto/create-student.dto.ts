import { IsMongoId, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateStudentDto {
  @IsString()
  @MinLength(1)
  uniNumber: string;

  @IsString()
  @MinLength(2)
  name: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsMongoId()
  department: string;

  @IsOptional()
  @IsMongoId()
  registrationOrder?: string;

  @IsOptional()
  @IsMongoId()
  project?: string | null;
}
