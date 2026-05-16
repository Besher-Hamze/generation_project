import { IsString, MinLength } from 'class-validator';

export class StudentLoginDto {
  @IsString()
  @MinLength(1)
  uniNumber: string;

  @IsString()
  @MinLength(1)
  password: string;
}
