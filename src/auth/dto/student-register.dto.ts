import { IsMongoId, IsOptional, IsString, MinLength } from 'class-validator';

export class StudentRegisterDto {
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

  /** اختياري — يحدد لاحقاً عبر طلب الانضمام أو مشروع شخصي (UML). */
  @IsOptional()
  @IsMongoId()
  project?: string;
}
