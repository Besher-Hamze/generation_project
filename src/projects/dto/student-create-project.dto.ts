import { IsString, MaxLength, MinLength } from 'class-validator';

export class StudentCreateProjectDto {
  @IsString()
  @MinLength(2)
  @MaxLength(300)
  title: string;

  @IsString()
  @MinLength(10)
  @MaxLength(8000)
  description: string;

  @IsString()
  @MinLength(4)
  @MaxLength(32)
  academicYear: string;
}
