import { PartialType } from '@nestjs/mapped-types';
import { CreateCommitteesDto } from './create-committees.dto';

export class UpdateCommitteesDto extends PartialType(CreateCommitteesDto) {}
