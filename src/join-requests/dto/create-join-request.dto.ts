import { IsMongoId } from 'class-validator';

export class CreateJoinRequestDto {
  @IsMongoId()
  projectId: string;
}
