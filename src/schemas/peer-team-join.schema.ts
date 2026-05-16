import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import {
  JOIN_REQUEST_STATUS,
  type JoinRequestStatus,
} from './join-request.schema';

export type PeerTeamJoinDocument = HydratedDocument<PeerTeamJoinRequest>;

/** طالب يريد الانضمام لفريق مشروع أنشده طالب آخر — الموافقة/الرفض من مالك المشروع. */
@Schema({ collection: 'peer_team_join_requests', timestamps: true })
export class PeerTeamJoinRequest {
  @Prop({ type: Types.ObjectId, ref: 'Student', required: true })
  requester: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  project: Types.ObjectId;

  @Prop({
    type: String,
    enum: JOIN_REQUEST_STATUS,
    default: 'pending',
  })
  status: JoinRequestStatus;
}

export const PeerTeamJoinSchema =
  SchemaFactory.createForClass(PeerTeamJoinRequest);

PeerTeamJoinSchema.index(
  { requester: 1, project: 1 },
  { unique: true, partialFilterExpression: { status: 'pending' } },
);
