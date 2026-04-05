import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type DepartmentDocument = HydratedDocument<Department>;

@Schema({ collection: 'departments', timestamps: true })
export class Department {
  @Prop({ required: true, unique: true, trim: true })
  name: string;
}

export const DepartmentSchema = SchemaFactory.createForClass(Department);
