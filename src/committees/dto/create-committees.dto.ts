import { IsMongoId, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateCommitteesDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  label?: string;

  @IsOptional()
  @IsMongoId()
  president?: string | null;
}
