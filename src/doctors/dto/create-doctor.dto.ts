import { IsEmail, IsMongoId, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateDoctorDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  @MinLength(1)
  officeNo: string;

  @IsString()
  @MinLength(1)
  phone: string;

  @IsMongoId()
  department: string;
}
