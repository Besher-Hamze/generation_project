import { IsMongoId } from 'class-validator';

export class CreateBlacklistDto {
  @IsMongoId()
  student: string;

  @IsMongoId()
  project: string;
}
