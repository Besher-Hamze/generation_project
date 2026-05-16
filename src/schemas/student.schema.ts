import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { hashPassword, isPasswordHashed } from '../common/password.util';

export type StudentDocument = HydratedDocument<Student>;

@Schema({ collection: 'students', timestamps: true })
export class Student {
  @Prop({ required: true, unique: true, trim: true })
  uniNumber: string;

  @Prop({ required: true, trim: true })
  name: string;

  /** Bcrypt hash; plain text is hashed on save. */
  @Prop({ required: true })
  password: string;

  @Prop({ type: Types.ObjectId, ref: 'RegistrationOrder', default: null })
  registrationOrder: Types.ObjectId | null;

  @Prop({ type: Types.ObjectId, ref: 'Department', required: true })
  department: Types.ObjectId;

  /** يُعيَّن بعد إنشاء مشروع أو قبول طلب انضمام. */
  @Prop({ type: Types.ObjectId, ref: 'Project', default: null })
  project: Types.ObjectId | null;
}

export const StudentSchema = SchemaFactory.createForClass(Student);

StudentSchema.pre('save', async function (next) {
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
  } catch (err) {
    next(err as Error);
  }
});
