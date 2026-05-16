import { IsEmail, IsString, MinLength } from 'class-validator';

export class DoctorLoginDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(1)
  password: string;
}
