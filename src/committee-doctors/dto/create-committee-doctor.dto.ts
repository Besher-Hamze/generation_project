import { IsBoolean, IsMongoId } from 'class-validator';

export class CreateCommitteeDoctorDto {
  @IsMongoId()
  committees: string;

  @IsMongoId()
  doctor: string;

  @IsBoolean()
  isPresident: boolean;
}
