import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type CommitteesDocument = HydratedDocument<Committees>;

/** لجنة — يمكن ربط رئيس اللجنة (كمشرف أساسي). */
@Schema({ collection: 'committees', strict: true, timestamps: true })
export class Committees {
  @Prop({ trim: true })
  label?: string;

  @Prop({ type: Types.ObjectId, ref: 'Doctor', default: null })
  president?: Types.ObjectId | null;
}

export const CommitteesSchema = SchemaFactory.createForClass(Committees);
