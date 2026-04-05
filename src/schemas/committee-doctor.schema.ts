import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type CommitteeDoctorDocument = HydratedDocument<CommitteeDoctor>;

@Schema({ collection: 'committee_doctors', timestamps: true })
export class CommitteeDoctor {
  @Prop({ type: Types.ObjectId, ref: 'Committees', required: true })
  committees: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Doctor', required: true })
  doctor: Types.ObjectId;

  @Prop({ type: Boolean, required: true, default: false })
  isPresident: boolean;
}

export const CommitteeDoctorSchema =
  SchemaFactory.createForClass(CommitteeDoctor);
