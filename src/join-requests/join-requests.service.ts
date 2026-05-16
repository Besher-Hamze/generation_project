import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { isSoloUnsupervisedStudentDraftProject } from '../projects/student-project-draft.util';
import { Blacklist } from '../schemas/blacklist.schema';
import { PeerTeamJoinRequest } from '../schemas/peer-team-join.schema';
import { Project } from '../schemas/project.schema';
import { Student } from '../schemas/student.schema';
import { CreateJoinRequestDto } from './dto/create-join-request.dto';
import { JoinRequestsRepository } from './repositories/join-requests.repository';

export const MAX_JOIN_REJECTIONS_BEFORE_BLOCK = 3;

@Injectable()
export class JoinRequestsService {
  constructor(
    private readonly repo: JoinRequestsRepository,
    @InjectModel(PeerTeamJoinRequest.name)
    private readonly peerJoins: Model<PeerTeamJoinRequest>,
    @InjectModel(Student.name) private readonly students: Model<Student>,
    @InjectModel(Project.name) private readonly projects: Model<Project>,
    @InjectModel(Blacklist.name) private readonly blacklist: Model<Blacklist>,
  ) {}

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

  private async doctorSupervisesProject(
    doctorId: string,
    projectId: string,
  ): Promise<boolean> {
    const oid = new Types.ObjectId(doctorId);
    const n = await this.projects.countDocuments({
      _id: new Types.ObjectId(projectId),
      $or: [{ supervisor: oid }, { supervisors: oid }],
    });
    return n > 0;
  }

  /** طلب انضمام لمشروع — موافقة الدكتور فقط (UML). */
  async create(requesterId: string, dto: CreateJoinRequestDto) {
    const blocked = await this.blacklist.exists({
      student: new Types.ObjectId(requesterId),
      project: new Types.ObjectId(dto.projectId),
    });
    if (blocked) {
      throw new ForbiddenException(
        'تم حظرك من إرسال طلبات جديدة لهذا المشروع بعد عدة رفض.',
      );
    }

    const requester = await this.students.findById(requesterId).lean().exec();
    if (!requester) {
      throw new NotFoundException('طالب غير موجود');
    }

    const currentProjectId = requester.project
      ? String(requester.project)
      : null;
    if (currentProjectId) {
      const currentProject = await this.projects
        .findById(currentProjectId)
        .lean()
        .exec();
      const isOwnDraft =
        currentProject &&
        isSoloUnsupervisedStudentDraftProject(requesterId, currentProject);

      if (!isOwnDraft) {
        if (currentProjectId === dto.projectId) {
          throw new BadRequestException('أنت مسجّل على هذا المشروع مسبقاً');
        }
        throw new ConflictException(
          'أنت مسجّل بمشروع يشرف عليه أستاذ؛ لا يمكن طلب الانضمام لفريق مشروع آخر قبل تعديل وضعك الأكاديمي.',
        );
      }
    }

    const project = await this.projects.findById(dto.projectId).exec();
    if (!project) {
      throw new NotFoundException('المشروع غير موجود');
    }

    if (project.isFinished === true) {
      throw new BadRequestException(
        'المشروع مُصفَّر كمنجز — لا يمكن طلب الانضمام.',
      );
    }

    if (project.createdByStudent) {
      throw new BadRequestException(
        'مشاريع طلّاب فرق الطلاب لا تستخدم هذا المسار — من التطبيق اختر «طلب انضمام لفريق الطالب».',
      );
    }

    const hasSupervisorStaff =
      project.supervisor != null ||
      (Array.isArray(project.supervisors) && project.supervisors.length > 0);
    if (!hasSupervisorStaff) {
      throw new BadRequestException(
        'طلب الانضمام لمشروع بلا مشرف أكاديمي غير مدعوم — اختر مشروعاً قائماً لا يقل عن مشرف واحد مرشّح في النظام.',
      );
    }

    const rid = new Types.ObjectId(requesterId);
    const pid = new Types.ObjectId(dto.projectId);

    const dup = await this.repo.findPendingForRequesterProject(rid, pid);
    if (dup) {
      throw new ConflictException('يوجد طلب معلّق مسبقاً لنفس المشروع');
    }

    return this.repo.create({
      requester: rid,
      project: pid,
      targetStudent: null,
    });
  }

  listOutgoing(requesterId: string) {
    return this.repo.listOutgoingForStudent(requesterId);
  }

  /** UML: Doctor → View pending join requests للمشاريع التي يشرف عليها. */
  async listPendingForDoctor(doctorId: string) {
    const pids = await this.supervisedProjectIds(doctorId);
    const rows = await this.repo.listPendingForProjects(pids);
    return Promise.all(rows.map(async (r) => {
      const projectRef = r.project as unknown;
      const pid =
        projectRef &&
        typeof projectRef === 'object' &&
        projectRef !== null &&
        '_id' in projectRef
          ? new Types.ObjectId(
              String((projectRef as { _id: unknown })._id),
            )
          : new Types.ObjectId(String(r.project));
      const teamMembersOnProject = await this.students
        .find({ project: pid })
        .select('name uniNumber')
        .sort({ name: 1 })
        .lean()
        .exec();
      return { ...r, teamMembersOnProject };
    }));
  }

  /** UML: Doctor → Approve request */
  async approveByDoctor(joinRequestId: string, doctorId: string) {
    const jr = await this.repo.findById(joinRequestId);
    if (!jr || jr.status !== 'pending') {
      throw new NotFoundException('الطلب غير موجود أو لم يعد معلّقاً');
    }
    if (!(await this.doctorSupervisesProject(doctorId, String(jr.project)))) {
      throw new ForbiddenException('ليس لديك صلاحية الموافقة على هذا الطلب');
    }

    const projDoc = await this.projects.findById(jr.project).lean().exec();
    if (projDoc?.isFinished === true) {
      throw new BadRequestException('المشروع منجز — لا يمكن قبول انضمام جديد.');
    }

    jr.status = 'accepted';
    await jr.save();

    await this.peerJoins
      .updateMany(
        { requester: jr.requester, status: 'pending' },
        { $set: { status: 'cancelled' } },
      )
      .exec();

    const stBefore = await this.students.findById(jr.requester).exec();
    const prevProjectId = stBefore?.project
      ? String(stBefore.project)
      : null;
    const grantedId = String(jr.project);

    if (prevProjectId && prevProjectId !== grantedId) {
      const prevDoc = await this.projects.findById(prevProjectId).lean().exec();
      if (
        prevDoc &&
        isSoloUnsupervisedStudentDraftProject(String(jr.requester), prevDoc)
      ) {
        await this.projects.findByIdAndUpdate(prevProjectId, {
          $set: { createdByStudent: null },
        });
      }
    }

    await this.students.findByIdAndUpdate(jr.requester, {
      $set: { project: jr.project },
    });

    await this.repo.rejectOtherPendingForStudent(
      jr.requester as Types.ObjectId,
      jr._id as Types.ObjectId,
    );

    const out = await this.repo.findPopulatedById(String(jr._id));
    if (!out) {
      throw new NotFoundException('الطلب غير موجود بعد الحفظ');
    }
    return out;
  }

  /** UML: Doctor → Reject request (+ blacklist بعد 3 رفض) */
  async rejectByDoctor(joinRequestId: string, doctorId: string) {
    const jr = await this.repo.findById(joinRequestId);
    if (!jr || jr.status !== 'pending') {
      throw new NotFoundException('الطلب غير موجود أو لم يعد معلّقاً');
    }
    if (!(await this.doctorSupervisesProject(doctorId, String(jr.project)))) {
      throw new ForbiddenException('ليس لديك صلاحية رفض هذا الطلب');
    }

    jr.status = 'rejected';
    await jr.save();

    const rejections = await this.repo.countRejectionsForRequesterOnProject(
      jr.requester as Types.ObjectId,
      jr.project as Types.ObjectId,
    );

    let blockedFromProject = false;
    if (rejections >= MAX_JOIN_REJECTIONS_BEFORE_BLOCK) {
      try {
        await this.blacklist.create({
          student: jr.requester,
          project: jr.project,
        });
        blockedFromProject = true;
      } catch {
        blockedFromProject = true;
      }
    }

    return {
      status: 'rejected',
      rejectionCountOnProject: rejections,
      blockedFromProject,
    };
  }
}

