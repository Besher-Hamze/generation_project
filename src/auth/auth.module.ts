import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { SchemasModule } from '../schemas/schemas.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { DoctorOnlyGuard } from './guards/doctor-only.guard';
import { JwtStrategy } from './jwt.strategy';

@Global()
@Module({
  imports: [
    SchemasModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET') ?? 'dev-change-me',
        signOptions: {
          expiresIn: Number(config.get('JWT_EXPIRES_SEC') ?? 604800),
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, DoctorOnlyGuard],
  exports: [AuthService, JwtModule, PassportModule],
})
export class AuthModule {}
