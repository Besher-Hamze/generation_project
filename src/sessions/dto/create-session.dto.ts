import { IsDateString, IsMongoId, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateSessionDto {
  @IsOptional()
  @IsNumber()
  mark?: number;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsNumber()
  sessionNum?: number;

  @IsMongoId()
  project: string;

  @IsOptional()
  @IsMongoId()
  /** يحدده المشرف عند إنشاء جلسة نيابة عن دكتور. */
  doctor?: string;

  @IsOptional()
  @IsString()
  title?: string;

  /** تاريخ الجلسة (ISO). */
  @IsOptional()
  @IsDateString()
  heldAt?: string;
}
