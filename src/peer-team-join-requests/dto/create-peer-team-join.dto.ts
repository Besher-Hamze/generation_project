import { IsMongoId } from 'class-validator';

export class CreatePeerTeamJoinDto {
  @IsMongoId()
  projectId: string;
}
