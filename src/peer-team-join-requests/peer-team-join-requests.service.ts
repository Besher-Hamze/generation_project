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
import { JoinRequest } from '../schemas/join-request.schema';
import { PeerTeamJoinRequest } from '../schemas/peer-team-join.schema';
import { Project } from '../schemas/project.schema';
import { Student } from '../schemas/student.schema';
import { CreatePeerTeamJoinDto } from './dto/create-peer-team-join.dto';

export const MAX_PEER_TEAM_REJECT_BEFORE_BLOCK = 3;

@Injectable()
export class PeerTeamJoinRequestsService {
  constructor(
    @InjectModel(PeerTeamJoinRequest.name)
    private readonly peers: Model<PeerTeamJoinRequest>,
    @InjectModel(JoinRequest.name)
    private readonly doctorJoins: Model<JoinRequest>,
    @InjectModel(Student.name)
    private readonly students: Model<Student>,
    @InjectModel(Project.name)
    private readonly projects: Model<Project>,
    @InjectModel(Blacklist.name)
    private readonly blacklist: Model<Blacklist>,
  ) {}

  async create(requesterId: string, dto: CreatePeerTeamJoinDto) {
    const blocked = await this.blacklist.exists({
      student: new Types.ObjectId(requesterId),
      project: new Types.ObjectId(dto.projectId),
    });
    if (blocked) {
      throw new ForbiddenException(
        'تم تقييدك على هذا المشروع بعد عدة رفض من صاحب الفريق.',
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
      const cur = await this.projects.findById(currentProjectId).lean().exec();
      const isOwnDraft =
        cur &&
        isSoloUnsupervisedStudentDraftProject(requesterId, cur);

      if (!isOwnDraft) {
        if (currentProjectId === dto.projectId) {
          throw new BadRequestException('أنت ضمن هذا المشروع مسبقاً');
        }
        throw new ConflictException(
          'مسجَّل بفريق آخر؛ لا يمكن طلب انضمام جديد قبل مغادرة ذلك التسجيل.',
        );
      }
    }

    const project = await this.projects.findById(dto.projectId).lean().exec();
    if (!project) {
      throw new NotFoundException('المشروع غير موجود');
    }

    if (project.isFinished === true) {
      throw new BadRequestException(
        'المشروع مُصفَّر كمنجز — لا يمكن طلب الانضمام للفريق.',
      );
    }

    const enrollingClosed =
      project.enrollmentOpen === undefined ? false : project.enrollmentOpen === false;
    if (enrollingClosed) {
      throw new BadRequestException(
        'صاحب المشروع أوقف قبول طلبات الانضمام لفريقه.',
      );
    }

    const maxTmRaw =
      project.maxTeamMembers === undefined || project.maxTeamMembers === null
        ? null
        : Number(project.maxTeamMembers);
    const memberCount = await this.students.countDocuments({
      project: new Types.ObjectId(dto.projectId),
    });
    if (maxTmRaw != null && Number.isFinite(maxTmRaw) && memberCount >= maxTmRaw) {
      throw new BadRequestException(
        'الفريق بلغ العدد الأقصى المحدّد — لا يمكن إرسال طلب انضمام.',
      );
    }

    const ownerId = project.createdByStudent
      ? String(project.createdByStudent)
      : null;
    if (!ownerId) {
      throw new BadRequestException(
        'هذا المشروع ليس مشروع فريق طالب — استخدم «طلب الانضمام لمشروع مشرف» للمشاريع الأكاديمية التقليدية.',
      );
    }
    if (ownerId === requesterId) {
      throw new BadRequestException('لا يمكنك طلب الانضمام لمشروع أنت منشئُه');
    }

    const dup = await this.peers
      .findOne({
        requester: new Types.ObjectId(requesterId),
        project: new Types.ObjectId(dto.projectId),
        status: 'pending',
      })
      .exec();
    if (dup) {
      throw new ConflictException('طلب معلّق مسبقاً لنفس مشروع الفريق');
    }

    return this.peers.create({
      requester: new Types.ObjectId(requesterId),
      project: new Types.ObjectId(dto.projectId),
      status: 'pending',
    });
  }

  listOutgoing(requesterId: string) {
    return this.peers
      .find({ requester: requesterId })
      .populate('project')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async listIncoming(ownerStudentId: string) {
    const owned = await this.projects
      .find({ createdByStudent: new Types.ObjectId(ownerStudentId) })
      .select('_id')
      .lean()
      .exec();
    const ids = owned.map((x) => x._id as Types.ObjectId);
    if (!ids.length) {
      return [];
    }
    return this.peers
      .find({ project: { $in: ids }, status: 'pending' })
      .populate('requester', '-password')
      .populate('project')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async approve(ownerStudentId: string, peerId: string) {
    const jr = await this.peers.findById(peerId).exec();
    if (!jr || jr.status !== 'pending') {
      throw new NotFoundException('الطلب غير موجود أو لم يعد معلّقاً');
    }
    const proj = await this.projects.findById(jr.project).lean().exec();
    if (!proj || String(proj.createdByStudent) !== ownerStudentId) {
      throw new ForbiddenException('لست مالك هذا المشروع');
    }

    if (proj.isFinished === true) {
      throw new BadRequestException('المشروع منجز — لا يمكن قبول طالب جديد.');
    }

    const enrollingClosed =
      proj.enrollmentOpen === undefined ? false : proj.enrollmentOpen === false;
    if (enrollingClosed) {
      throw new BadRequestException('الانتساب مغلق — لا يمكن قبول هذا الطلب.');
    }

    const memberCount = await this.students.countDocuments({
      project: jr.project as Types.ObjectId,
    });
    const maxTm =
      proj.maxTeamMembers === undefined || proj.maxTeamMembers === null
        ? null
        : Number(proj.maxTeamMembers);
    if (
      maxTm != null &&
      Number.isFinite(maxTm) &&
      memberCount >= maxTm
    ) {
      throw new ConflictException(
        'الفريق مكتمل بعدد الطلاب المسموح — ارفض الطلب أو زِد السقف من إعدادات الفريق.',
      );
    }

    jr.status = 'accepted';
    await jr.save();

    await this.cancelAllDoctorJoinPendingForStudent(
      jr.requester as Types.ObjectId,
    );
    await this.peers
      .updateMany(
        {
          requester: jr.requester,
          status: 'pending',
          _id: { $ne: jr._id },
        },
        { $set: { status: 'cancelled' } },
      )
      .exec();

    await this.finalizeAcceptedJoinAssignment(String(jr.requester), String(jr.project));
    await this.maybeAutoCloseEnrollment(jr.project as Types.ObjectId);

    const out = await this.peers
      .findById(jr._id)
      .populate('requester', '-password')
      .populate('project')
      .lean()
      .exec();
    if (!out) {
      throw new NotFoundException('الطلب غير موجود بعد الحفظ');
    }
    return out;
  }

  async reject(ownerStudentId: string, peerId: string) {
    const jr = await this.peers.findById(peerId).exec();
    if (!jr || jr.status !== 'pending') {
      throw new NotFoundException('الطلب غير موجود أو لم يعد معلّقاً');
    }
    const proj = await this.projects.findById(jr.project).lean().exec();
    if (!proj || String(proj.createdByStudent) !== ownerStudentId) {
      throw new ForbiddenException('لست مالك هذا المشروع');
    }

    jr.status = 'rejected';
    await jr.save();

    const rejects = await this.peers.countDocuments({
      requester: jr.requester,
      project: jr.project,
      status: 'rejected',
    });
    let blockedFromProject = false;
    if (rejects >= MAX_PEER_TEAM_REJECT_BEFORE_BLOCK) {
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
      rejectionCountOnProject: rejects,
      blockedFromProject,
    };
  }

  private cancelAllDoctorJoinPendingForStudent(sid: Types.ObjectId) {
    return this.doctorJoins
      .updateMany(
        { requester: sid, status: 'pending' },
        { $set: { status: 'cancelled' } },
      )
      .exec();
  }

  private async finalizeAcceptedJoinAssignment(requesterStr: string, grantedId: string) {
    const stBefore = await this.students.findById(requesterStr).exec();
    const prevProjectId = stBefore?.project
      ? String(stBefore.project)
      : null;

    if (
      prevProjectId &&
      prevProjectId !== grantedId
    ) {
      const prevDoc = await this.projects.findById(prevProjectId).lean().exec();
      if (
        prevDoc &&
        isSoloUnsupervisedStudentDraftProject(requesterStr, prevDoc)
      ) {
        await this.projects.findByIdAndUpdate(prevProjectId, {
          $set: { createdByStudent: null },
        });
      }
    }

    await this.students.findByIdAndUpdate(requesterStr, {
      $set: { project: new Types.ObjectId(grantedId) },
    });
  }

  /** عند الوصول للحد الأقصى يُغلق الانتساب تلقائياً. */
  private async maybeAutoCloseEnrollment(projectId: Types.ObjectId) {
    const proj = await this.projects.findById(projectId).lean().exec();
    if (!proj) {
      return;
    }
    const maxTm =
      proj.maxTeamMembers === undefined || proj.maxTeamMembers === null
        ? null
        : Number(proj.maxTeamMembers);
    if (maxTm == null || !Number.isFinite(maxTm)) {
      return;
    }
    const n = await this.students.countDocuments({ project: projectId });
    if (n >= maxTm) {
      await this.projects
        .updateOne({ _id: projectId }, { $set: { enrollmentOpen: false } })
        .exec();
    }
  }
}
