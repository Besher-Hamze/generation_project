import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Admin, AdminSchema } from './admin.schema';
import { Blacklist, BlacklistSchema } from './blacklist.schema';
import { CommitteeDoctor, CommitteeDoctorSchema } from './committee-doctor.schema';
import { Committees, CommitteesSchema } from './committees.schema';
import { Department, DepartmentSchema } from './department.schema';
import { Doctor, DoctorSchema } from './doctor.schema';
import { JoinRequest, JoinRequestSchema } from './join-request.schema';
import { PeerTeamJoinRequest, PeerTeamJoinSchema } from './peer-team-join.schema';
import { Project, ProjectSchema } from './project.schema';
import {
  RegistrationOrder,
  RegistrationOrderSchema,
} from './registration-order.schema';
import { Session, SessionSchema } from './session.schema';
import { Student, StudentSchema } from './student.schema';
import { SupervisionInvitation, SupervisionInvitationSchema } from './supervision-invitation.schema';
import { SystemSetting, SystemSettingSchema } from './system-setting.schema';

const models = [
  { name: Admin.name, schema: AdminSchema },
  { name: Department.name, schema: DepartmentSchema },
  { name: RegistrationOrder.name, schema: RegistrationOrderSchema },
  { name: Doctor.name, schema: DoctorSchema },
  { name: Student.name, schema: StudentSchema },
  { name: Committees.name, schema: CommitteesSchema },
  { name: JoinRequest.name, schema: JoinRequestSchema },
  { name: PeerTeamJoinRequest.name, schema: PeerTeamJoinSchema },
  { name: SupervisionInvitation.name, schema: SupervisionInvitationSchema },
  { name: Project.name, schema: ProjectSchema },
  { name: Session.name, schema: SessionSchema },
  { name: CommitteeDoctor.name, schema: CommitteeDoctorSchema },
  { name: Blacklist.name, schema: BlacklistSchema },
  { name: SystemSetting.name, schema: SystemSettingSchema },
];

@Module({
  imports: [MongooseModule.forFeature(models)],
  exports: [MongooseModule],
})
export class SchemasModule {}
