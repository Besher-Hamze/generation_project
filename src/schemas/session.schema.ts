import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type SessionDocument = HydratedDocument<Session>;

@Schema({ collection: 'sessions', timestamps: true })
export class Session {
  @Prop({ type: Number, required: true })
  mark: number;

  @Prop({ type: String, trim: true })
  notes?: string;

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  project: Types.ObjectId;
}

export const SessionSchema = SchemaFactory.createForClass(Session);
