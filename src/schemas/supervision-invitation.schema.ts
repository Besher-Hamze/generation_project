import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import {
  JOIN_REQUEST_STATUS,
  type JoinRequestStatus,
} from './join-request.schema';

export type SupervisionInvitationDocument = HydratedDocument<SupervisionInvitation>;

/** دعوات من الطالب لمشرف واحد لمشروعه؛ أول دكتور يقبل يلغي باقي الدعوات. */
@Schema({ collection: 'supervision_invitations', timestamps: true })
export class SupervisionInvitation {
  /** الطالب الذي يملك المشروع (= createdByStudent للمشروع). */
  @Prop({ type: Types.ObjectId, ref: 'Student', required: true })
  studentOwner: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  project: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Doctor', required: true })
  invitedDoctor: Types.ObjectId;

  @Prop({
    type: String,
    enum: JOIN_REQUEST_STATUS,
    default: 'pending',
  })
  status: JoinRequestStatus;
}

export const SupervisionInvitationSchema = SchemaFactory.createForClass(
  SupervisionInvitation,
);

SupervisionInvitationSchema.index(
  { project: 1, invitedDoctor: 1 },
  { unique: true, partialFilterExpression: { status: 'pending' } },
);
