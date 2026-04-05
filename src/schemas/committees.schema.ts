import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type CommitteesDocument = HydratedDocument<Committees>;

/** Committee shell; extend with fields (e.g. defense date) when you need them. */
@Schema({ collection: 'committees', strict: true, timestamps: true })
export class Committees {
  @Prop({ trim: true })
  label?: string;
}

export const CommitteesSchema = SchemaFactory.createForClass(Committees);
