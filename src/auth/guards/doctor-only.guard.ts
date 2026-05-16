import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { JwtPayload } from '../jwt.strategy';

@Injectable()
export class DoctorOnlyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const user = context.switchToHttp().getRequest<{ user?: JwtPayload }>()
      .user;
    if (!user) {
      throw new UnauthorizedException();
    }
    if (user.role !== 'doctor') {
      throw new ForbiddenException('هذا الإجراء متاح للدكاترة فقط');
    }
    return true;
  }
}
