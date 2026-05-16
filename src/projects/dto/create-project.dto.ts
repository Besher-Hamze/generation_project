import {
  IsArray,
  IsBoolean,
  IsMongoId,
  IsNumber,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

export class CreateProjectDto {
  @IsString()
  @MinLength(1)
  title: string;

  @IsString()
  @MinLength(1)
  description: string;

  @IsString()
  @MinLength(1)
  academicYear: string;

  @IsOptional()
  @IsBoolean()
  isFinished?: boolean;

  @IsOptional()
  @IsMongoId()
  committees?: string | null;

  @IsOptional()
  @IsNumber()
  mark?: number;

  /** If set with supervisorIds, primary supervisor id (optional override). */
  @IsOptional()
  @IsMongoId()
  supervisor?: string | null;

  @IsOptional()
  @IsArray()
  @IsMongoId({ each: true })
  supervisorIds?: string[];

  @IsOptional()
  @IsString()
  supervisorDisplayName?: string;
}
