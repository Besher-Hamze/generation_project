import { ArrayMinSize, IsMongoId } from 'class-validator';

export class SendSupervisionInvitesDto {
  @IsMongoId()
  projectId: string;

  @IsMongoId({ each: true })
  @ArrayMinSize(1)
  doctorIds: string[];
}
