import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, Max, Min } from 'class-validator';

export class TeamEnrollmentSettingsDto {
  @IsOptional()
  @IsBoolean()
  enrollmentOpen?: boolean;

  /** أقصى عدد طلاب على المشروع (بما فيه المنشئ). يُترك الحقل دون إرسال لعدم التغيير. */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  maxTeamMembers?: number;
}
