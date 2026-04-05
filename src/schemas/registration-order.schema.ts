import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type RegistrationOrderDocument = HydratedDocument<RegistrationOrder>;

@Schema({ collection: 'registration_orders', timestamps: true })
export class RegistrationOrder {
  @Prop({ type: Date, required: true })
  orderStart: Date;

  @Prop({ type: String, required: true, trim: true })
  orderStatus: string;
}

export const RegistrationOrderSchema =
  SchemaFactory.createForClass(RegistrationOrder);
