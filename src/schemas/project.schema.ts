import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type ProjectDocument = HydratedDocument<Project>;

@Schema({ collection: 'projects', timestamps: true })
export class Project {
  @Prop({ required: true, trim: true })
  title: string;

  @Prop({ required: true, trim: true })
  description: string;

  @Prop({ required: true, trim: true })
  academicYear: string;

  @Prop({ type: Boolean, required: true, default: false })
  isFinished: boolean;

  @Prop({ type: Types.ObjectId, ref: 'Committees', default: null })
  committees: Types.ObjectId | null;

  @Prop({ type: Number, required: true, default: 0 })
  mark: number;

  /** الطالب الذي أنشأ المشروع (UML: Student → Create Projects). */
  @Prop({ type: Types.ObjectId, ref: 'Student', default: null })
  createdByStudent: Types.ObjectId | null;

  /**
   * First supervisor (same as supervisors[0] when seeded from CSV).
   * Kept for simple lookups; prefer supervisors when there are co-supervisors.
   */
  @Prop({ type: Types.ObjectId, ref: 'Doctor', default: null })
  supervisor: Types.ObjectId | null;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'Doctor' }], default: [] })
  supervisors: Types.ObjectId[];

  /** Raw cell from CSV before splitting on `_`. */
  @Prop({ trim: true })
  supervisorDisplayName?: string;

  /** مشاريع الفرق: قبول طلبات انضمام طلاب جدد (يغلقها قائد الفريق عند اكتمال العدد). */
  @Prop({ type: Boolean, required: true, default: true })
  enrollmentOpen: boolean;

  /**
   * أقصى عدد طلاب مسجّلين على المشروع (بما فيه المنشئ).
   * null = بلا سقف عددي (ما دام enrollmentOpen).
   */
  @Prop({ type: Number, required: false, default: null })
  maxTeamMembers: number | null;
}

export const ProjectSchema = SchemaFactory.createForClass(Project);

ProjectSchema.index({ title: 1, academicYear: 1 });
