import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Doctor } from '../schemas/doctor.schema';
import { Project } from '../schemas/project.schema';
import { SupervisionInvitation } from '../schemas/supervision-invitation.schema';
import { SendSupervisionInvitesDto } from './dto/send-supervision-invites.dto';

@Injectable()
export class SupervisionInvitationsService {
  constructor(
    @InjectModel(SupervisionInvitation.name)
    private readonly invites: Model<SupervisionInvitation>,
    @InjectModel(Project.name)
    private readonly projects: Model<Project>,
    @InjectModel(Doctor.name)
    private readonly doctors: Model<Doctor>,
  ) {}

  async send(studentOwnerId: string, dto: SendSupervisionInvitesDto) {
    const project = await this.projects.findById(dto.projectId).exec();
    if (!project) {
      throw new NotFoundException('المشروع غير موجود');
    }
    if (!project.createdByStudent) {
      throw new BadRequestException('هذا ليس مشروعاً أنشأه طالب');
    }
    if (String(project.createdByStudent) !== studentOwnerId) {
      throw new ForbiddenException('لا تملك هذا المشروع');
    }
    if (project.isFinished === true) {
      throw new BadRequestException(
        'المشروع مُعلَّم كمنجز — لا يمكن إرسال دعوات إشراف جديدة.',
      );
    }
    const hasSup =
      project.supervisor != null ||
      (Array.isArray(project.supervisors) && project.supervisors.length > 0);
    if (hasSup) {
      throw new ConflictException(
        'المشروع يملك مشرفاً بالفعل — لا يمكن إرسال دعوات جديدة.',
      );
    }

    const created: SupervisionInvitation[] = [];
    const seen = new Set<string>();
    for (const raw of dto.doctorIds) {
      const did = String(raw);
      if (seen.has(did)) {
        continue;
      }
      seen.add(did);
      const doc = await this.doctors.findById(did).exec();
      if (!doc) {
        throw new NotFoundException(`دكتور غير موجود: ${did}`);
      }
      try {
        const inv = await this.invites.create({
          studentOwner: new Types.ObjectId(studentOwnerId),
          project: project._id,
          invitedDoctor: new Types.ObjectId(did),
          status: 'pending',
        });
        created.push(inv);
      } catch (e: unknown) {
        const code = (e as { code?: number })?.code;
        if (code === 11000) {
          continue;
        }
        throw e;
      }
    }
    if (!created.length) {
      throw new BadRequestException('لم يُنشأ أي طلب دعوة جديد (تكرار أو أخطاء).');
    }
    return created;
  }

  listOutgoing(studentOwnerId: string) {
    /* استخدم ObjectId صريحًا: بعض إصدارات/إعدادات الاستعلام لا تطبِّع السلسلة تلقائياً إلى ObjectId كما المتوقّع، فيُعاد قائمة فارغة رغم وجود الوثائق. */
    if (!Types.ObjectId.isValid(studentOwnerId)) {
      return Promise.resolve([]);
    }
    const oid = new Types.ObjectId(studentOwnerId);
    return this.invites
      .find({
        $or: [{ studentOwner: oid }, { studentOwner: studentOwnerId }],
      })
      .populate('project')
      .populate('invitedDoctor', '-password')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  listPendingForDoctor(doctorId: string) {
    if (!Types.ObjectId.isValid(doctorId)) {
      return Promise.resolve([]);
    }
    const oid = new Types.ObjectId(doctorId);
    return this.invites
      .find({
        $or: [{ invitedDoctor: oid }, { invitedDoctor: doctorId }],
        status: 'pending',
      })
      .populate('project')
      .populate('studentOwner', '-password')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async acceptByDoctor(doctorId: string, invitationId: string) {
    const inv = await this.invites.findById(invitationId).exec();
    if (!inv || inv.status !== 'pending') {
      throw new NotFoundException('الدعوة غير موجودة أو لم تعد معلّقة');
    }
    if (String(inv.invitedDoctor) !== doctorId) {
      throw new ForbiddenException('هذه الدعوة ليست لحسابك');
    }

    const docOid = new Types.ObjectId(doctorId);

    await this.projects.findByIdAndUpdate(inv.project, {
      $set: {
        supervisor: docOid,
        supervisors: [docOid],
      },
    });

    inv.status = 'accepted';
    await inv.save();

    await this.invites
      .updateMany(
        {
          project: inv.project,
          status: 'pending',
          _id: { $ne: inv._id },
        },
        { $set: { status: 'cancelled' } },
      )
      .exec();

    return this.invites
      .findById(inv._id)
      .populate('studentOwner', '-password')
      .populate('project')
      .populate('invitedDoctor', '-password')
      .lean()
      .exec();
  }

  async rejectByDoctor(doctorId: string, invitationId: string) {
    const inv = await this.invites.findById(invitationId).exec();
    if (!inv || inv.status !== 'pending') {
      throw new NotFoundException('الدعوة غير موجودة أو لم تعد معلّقة');
    }
    if (String(inv.invitedDoctor) !== doctorId) {
      throw new ForbiddenException('هذه الدعوة ليست لحسابك');
    }
    inv.status = 'rejected';
    await inv.save();
    return { status: 'rejected' as const };
  }
}
