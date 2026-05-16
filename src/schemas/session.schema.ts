import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SessionDocument = HydratedDocument<Session>;

@Schema({ collection: 'sessions', timestamps: true })
export class Session {
  @Prop({ type: Number, required: true })
  mark: number;

  /** رقم الجلسة (مطابق لمخطط ER). */
  @Prop({ type: Number, default: null })
  sessionNum: number | null;

  @Prop({ type: String, trim: true })
  notes?: string;

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  project: Types.ObjectId;

  /** الدكتور صاحب الجلسة (إشراف). */
  @Prop({ type: Types.ObjectId, ref: 'Doctor', default: null })
  doctor: Types.ObjectId | null;

  @Prop({ trim: true })
  title?: string;

  @Prop({ type: Date, default: null })
  heldAt: Date | null;
}

export const SessionSchema = SchemaFactory.createForClass(Session);

SessionSchema.index({ project: 1, createdAt: -1 });
SessionSchema.index({ doctor: 1, createdAt: -1 });
