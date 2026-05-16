import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type JoinRequestDocument = HydratedDocument<JoinRequest>;

export const JOIN_REQUEST_STATUS = [
  'pending',
  'accepted',
  'rejected',
  'cancelled',
] as const;
export type JoinRequestStatus = (typeof JOIN_REQUEST_STATUS)[number];

/** طلب من طالب للانضمام إلى مشروع؛ تُدار الموافقة/الرفض من الدكتور المشرف. */
@Schema({ collection: 'join_requests', timestamps: true })
export class JoinRequest {
  @Prop({ type: Types.ObjectId, ref: 'Student', required: true })
  requester: Types.ObjectId;

  /** حقل قديم للتوافق مع السجلات السابقة؛ يُترك فارغاً للطلبات الجديدة. */
  @Prop({ type: Types.ObjectId, ref: 'Student', default: null })
  targetStudent?: Types.ObjectId | null;

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  project: Types.ObjectId;

  @Prop({
    type: String,
    enum: JOIN_REQUEST_STATUS,
    default: 'pending',
  })
  status: JoinRequestStatus;
}

export const JoinRequestSchema = SchemaFactory.createForClass(JoinRequest);

JoinRequestSchema.index(
  { requester: 1, project: 1 },
  { unique: true, partialFilterExpression: { status: 'pending' } },
);
JoinRequestSchema.index({ requester: 1, project: 1, status: 1 });
