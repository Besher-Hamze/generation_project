import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { JwtPayload } from '../jwt.strategy';

@Injectable()
export class DoctorOrAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const user = context.switchToHttp().getRequest<{ user?: JwtPayload }>()
      .user;
    if (!user) {
      throw new UnauthorizedException();
    }
    if (user.role !== 'doctor' && user.role !== 'admin') {
      throw new ForbiddenException('يتطلب صلاحية دكتور أو مشرف نظام');
    }
    return true;
  }
}
