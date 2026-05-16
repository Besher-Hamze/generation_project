import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { AdminLoginDto } from './dto/admin-login.dto';
import { DoctorLoginDto } from './dto/doctor-login.dto';
import { StudentLoginDto } from './dto/student-login.dto';
import { StudentRegisterDto } from './dto/student-register.dto';
import { ChangeDoctorPasswordDto } from './dto/change-doctor-password.dto';
import type { JwtPayload } from './jwt.strategy';
import { CurrentUser } from './current-user.decorator';
import { DoctorOnlyGuard } from './guards/doctor-only.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('admin/login')
  adminLogin(@Body() dto: AdminLoginDto) {
    return this.auth.adminLogin(dto);
  }

  @Post('doctor/login')
  doctorLogin(@Body() dto: DoctorLoginDto) {
    return this.auth.doctorLogin(dto);
  }

  @Post('student/login')
  studentLogin(@Body() dto: StudentLoginDto) {
    return this.auth.studentLogin(dto);
  }

  /** تسجيل الطلاب فقط — حسابات الدكاترة يُنشئها المشرف. */
  @Post('student/register')
  studentRegister(@Body() dto: StudentRegisterDto) {
    return this.auth.studentRegister(dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me')
  me(@CurrentUser() user: JwtPayload) {
    return this.auth.me(user);
  }

  /** تغيير كلمة مرور حساب الدكتور (وهو الذي يحمي الجلسات). */
  @Patch('doctor/password')
  @UseGuards(AuthGuard('jwt'), DoctorOnlyGuard)
  doctorPassword(
    @CurrentUser() user: JwtPayload,
    @Body() dto: ChangeDoctorPasswordDto,
  ) {
    return this.auth.changeDoctorPassword(user.sub, dto);
  }
}
