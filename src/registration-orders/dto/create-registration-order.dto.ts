import { IsDateString, IsString, MinLength } from 'class-validator';

export class CreateRegistrationOrderDto {
  @IsDateString()
  orderStart: string;

  @IsString()
  @MinLength(1)
  orderStatus: string;
}
