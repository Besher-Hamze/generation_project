import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type SystemSettingDocument = HydratedDocument<SystemSetting>;

/** ثوابت قابلة للتهيئة — Use case: Admin → Input Constants */
@Schema({ collection: 'system_settings', timestamps: true })
export class SystemSetting {
  @Prop({ required: true, unique: true, trim: true })
  key: string;

  @Prop({ required: true, trim: true })
  value: string;

  @Prop({ trim: true })
  description?: string;
}

export const SystemSettingSchema =
  SchemaFactory.createForClass(SystemSetting);
