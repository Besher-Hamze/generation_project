import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { hashPassword, isPasswordHashed } from '../common/password.util';

export type AdminDocument = HydratedDocument<Admin>;

@Schema({ collection: 'admins', timestamps: true })
export class Admin {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true, unique: true, trim: true, lowercase: true })
  email: string;

  @Prop({ required: true })
  password: string;
}

export const AdminSchema = SchemaFactory.createForClass(Admin);

AdminSchema.index({ email: 1 }, { unique: true });

AdminSchema.pre('save', async function (next) {
  try {
    if (this.isModified('password')) {
      const pwd = this.get('password');
      if (
        typeof pwd === 'string' &&
        pwd.length > 0 &&
        !isPasswordHashed(pwd)
      ) {
        this.set('password', await hashPassword(pwd));
      }
    }
    next();
  } catch (e) {
    next(e as Error);
  }
});
