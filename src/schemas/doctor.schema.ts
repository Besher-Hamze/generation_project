import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { normalizeArabicNameKey } from '../common/arabic-name-key';
import { hashPassword, isPasswordHashed } from '../common/password.util';

export type DoctorDocument = HydratedDocument<Doctor>;

@Schema({ collection: 'doctors', timestamps: true })
export class Doctor {
  /** Display / CSV spelling (first seen kept when merging duplicates). */
  @Prop({ required: true, trim: true })
  name: string;

  /** Canonical dedupe key: {@link normalizeArabicNameKey} of `name`. */
  @Prop({ required: true, trim: true, lowercase: true })
  nameKey: string;

  @Prop({ required: true, trim: true, lowercase: true })
  email: string;

  /** Bcrypt hash; plain text is hashed on save (see pre-save hook). */
  @Prop({ required: true })
  password: string;

  @Prop({ required: true, trim: true })
  officeNo: string;

  @Prop({ required: true, trim: true })
  phone: string;

  @Prop({ type: Types.ObjectId, ref: 'Department', required: true })
  department: Types.ObjectId;
}

export const DoctorSchema = SchemaFactory.createForClass(Doctor);

DoctorSchema.index({ email: 1 }, { unique: true });
DoctorSchema.index({ department: 1, nameKey: 1 }, { unique: true });

DoctorSchema.pre('save', async function (next) {
  try {
    if (this.isModified('name') || !this.get('nameKey')) {
      const n = this.get('name');
      if (typeof n === 'string' && n.length > 0) {
        this.set('nameKey', normalizeArabicNameKey(n));
      }
    }
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
  } catch (err) {
    next(err as Error);
  }
});
