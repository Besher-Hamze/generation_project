import { IsInt, Max, Min } from 'class-validator';

export class DefenseFinalMarkDto {
  @IsInt()
  @Min(0)
  @Max(100)
  mark: number;
}
