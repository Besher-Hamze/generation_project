import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type BlacklistDocument = HydratedDocument<Blacklist>;

@Schema({ collection: 'blacklists', timestamps: true })
export class Blacklist {
  @Prop({ type: Types.ObjectId, ref: 'Student', required: true })
  student: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Project', required: true })
  project: Types.ObjectId;
}

export const BlacklistSchema = SchemaFactory.createForClass(Blacklist);
