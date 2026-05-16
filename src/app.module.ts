import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { BlacklistsModule } from './blacklists/blacklists.module';
import { CommitteeDoctorsModule } from './committee-doctors/committee-doctors.module';
import { CommitteesModule } from './committees/committees.module';
import { DatabaseModule } from './database/database.module';
import { DepartmentsModule } from './departments/departments.module';
import { DoctorsModule } from './doctors/doctors.module';
import { AiChatProxyModule } from './integrations/ai-chat-proxy.module';
import { JoinRequestsModule } from './join-requests/join-requests.module';
import { PeerTeamJoinRequestsModule } from './peer-team-join-requests/peer-team-join-requests.module';
import { ProjectsModule } from './projects/projects.module';
import { SupervisionInvitationsModule } from './supervision-invitations/supervision-invitations.module';
import { PublicModule } from './public/public.module';
import { RegistrationOrdersModule } from './registration-orders/registration-orders.module';
import { SessionsModule } from './sessions/sessions.module';
import { StudentsModule } from './students/students.module';
import { SystemSettingsModule } from './system-settings/system-settings.module';

@Module({
  imports: [
    DatabaseModule,
    AuthModule,
    PublicModule,
    DepartmentsModule,
    RegistrationOrdersModule,
    CommitteesModule,
    ProjectsModule,
    DoctorsModule,
    StudentsModule,
    SessionsModule,
    JoinRequestsModule,
    PeerTeamJoinRequestsModule,
    SupervisionInvitationsModule,
    CommitteeDoctorsModule,
    BlacklistsModule,
    SystemSettingsModule,
    AiChatProxyModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
