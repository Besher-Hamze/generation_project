import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import type { JwtPayload } from '../auth/jwt.strategy';
import { Project } from '../schemas/project.schema';
import { Session } from '../schemas/session.schema';
import { Student } from '../schemas/student.schema';
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';
import { SessionsRepository } from './repositories/sessions.repository';

@Injectable()
export class SessionsService {
  constructor(
    private readonly repo: SessionsRepository,
    @InjectModel(Project.name) private readonly projects: Model<Project>,
    @InjectModel(Student.name) private readonly students: Model<Student>,
  ) {}

  private extractProjectId(projectField: unknown): string {
    if (
      projectField &&
      typeof projectField === 'object' &&
      '_id' in projectField
    ) {
      return String((projectField as { _id: unknown })._id);
    }
    return String(projectField);
  }

  private async doctorSupervisesProject(
    doctorId: string,
    projectId: string,
  ): Promise<boolean> {
    const oid = new Types.ObjectId(doctorId);
    const count = await this.projects.countDocuments({
      _id: new Types.ObjectId(projectId),
      $or: [{ supervisor: oid }, { supervisors: oid }],
    });
    return count > 0;
  }

  private async supervisedProjectIds(
    doctorId: string,
  ): Promise<Types.ObjectId[]> {
    const oid = new Types.ObjectId(doctorId);
    const rows = await this.projects
      .find({
        $or: [{ supervisor: oid }, { supervisors: oid }],
      })
      .select('_id')
      .lean()
      .exec();
    return rows.map((r) => r._id as Types.ObjectId);
  }

  /** دكتور مشرف على المشروع: جلسات الإشراف. */
  async createForActor(actor: JwtPayload, dto: CreateSessionDto) {
    const heldAt = dto.heldAt ? new Date(dto.heldAt) : new Date();
    const sessionNum =
      dto.sessionNum !== undefined && dto.sessionNum !== null
        ? dto.sessionNum
        : null;
    const mark = dto.mark ?? 0;

    if (actor.role !== 'doctor') {
      throw new ForbiddenException(
        'تسجيل الجلسات لا يكون من حساب الإدارة — من حساب الدكتور المشرف.',
      );
    }

    const ok = await this.doctorSupervisesProject(actor.sub, dto.project);
    if (!ok) {
      throw new ForbiddenException('لست مشرفاً على هذا المشروع');
    }

    return this.repo.insertOne({
      mark,
      notes: dto.notes ?? undefined,
      sessionNum,
      project: new Types.ObjectId(dto.project),
      doctor: new Types.ObjectId(actor.sub),
      title: dto.title,
      heldAt,
    });
  }

  async findForCurrentUser(user: JwtPayload) {
    if (user.role === 'admin') {
      return [];
    }
    if (user.role === 'student') {
      const st = await this.students.findById(user.sub).lean().exec();
      if (!st?.project) {
        return [];
      }
      return this.repo.findMany({ project: st.project });
    }
    if (user.role === 'doctor') {
      const pids = await this.supervisedProjectIds(user.sub);
      const oid = new Types.ObjectId(user.sub);
      return this.repo.findMany({
        $or: [{ doctor: oid }, { project: { $in: pids } }],
      });
    }
    return [];
  }

  async findOneVisible(user: JwtPayload, id: string) {
    const doc = await this.repo.findByIdLeanPopulated(id);
    if (!doc) {
      throw new NotFoundException('الجلسة غير موجودة');
    }
    const projectId = this.extractProjectId(
      (doc as unknown as { project: unknown }).project,
    );

    if (user.role === 'admin') {
      return doc;
    }
    if (user.role === 'student') {
      const st = await this.students.findById(user.sub).lean().exec();
      if (!st?.project || String(st.project) !== projectId) {
        throw new ForbiddenException();
      }
      return doc;
    }
    if (user.role === 'doctor') {
      const ok = await this.doctorSupervisesProject(user.sub, projectId);
      if (!ok) {
        throw new ForbiddenException();
      }
      return doc;
    }
    throw new ForbiddenException();
  }

  private async assertDoctorCanMutateSession(
    doctorId: string,
    session: Session,
  ) {
    const projectId = String(session.project);
    if (!(await this.doctorSupervisesProject(doctorId, projectId))) {
      throw new ForbiddenException('لست مشرفاً على مشروع هذه الجلسة');
    }
    if (session.doctor && String(session.doctor) !== doctorId) {
      throw new ForbiddenException('هذه الجلسة مسجّلة باسم دكتور آخر');
    }
  }

  async updateForActor(actor: JwtPayload, id: string, dto: UpdateSessionDto) {
    const session = await this.repo.findById(id);
    if (!session) {
      throw new NotFoundException('الجلسة غير موجودة');
    }

    if (actor.role !== 'doctor') {
      throw new ForbiddenException(
        'تعديل الجلسات متاح لتسجيل الدكتور المشرف على المشروع فقط.',
      );
    }
    await this.assertDoctorCanMutateSession(actor.sub, session);

    const patch: Record<string, unknown> = {};
    if (dto.mark !== undefined) {
      patch.mark = dto.mark;
    }
    if (dto.notes !== undefined) {
      patch.notes = dto.notes;
    }
    if (dto.title !== undefined) {
      patch.title = dto.title;
    }
    if (dto.sessionNum !== undefined) {
      patch.sessionNum = dto.sessionNum;
    }
    if (dto.heldAt !== undefined) {
      patch.heldAt = dto.heldAt ? new Date(dto.heldAt) : null;
    }
    if (dto.project !== undefined && dto.project !== String(session.project)) {
      throw new ForbiddenException('لا يمكن تغيير المشروع');
    }

    const doc = await this.repo.updateById(id, patch);
    if (!doc) {
      throw new NotFoundException('الجلسة غير موجودة');
    }
    return doc;
  }

  async removeForActor(actor: JwtPayload, id: string) {
    const session = await this.repo.findById(id);
    if (!session) {
      throw new NotFoundException('الجلسة غير موجودة');
    }
    if (actor.role !== 'doctor') {
      throw new ForbiddenException(
        'حذف الجلسات لا يكون من حساب الإدارة.',
      );
    }
    await this.assertDoctorCanMutateSession(actor.sub, session);
    await this.repo.deleteById(id);
    return { deleted: true };
  }
}
