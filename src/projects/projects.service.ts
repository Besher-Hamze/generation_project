import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Blacklist } from '../schemas/blacklist.schema';
import { CommitteeDoctor } from '../schemas/committee-doctor.schema';
import { JoinRequest } from '../schemas/join-request.schema';
import { PeerTeamJoinRequest } from '../schemas/peer-team-join.schema';
import { Session } from '../schemas/session.schema';
import { SupervisionInvitation } from '../schemas/supervision-invitation.schema';
import { Project } from '../schemas/project.schema';
import { Student } from '../schemas/student.schema';
import { CreateProjectDto } from './dto/create-project.dto';
import { DefenseFinalMarkDto } from './dto/defense-final-mark.dto';
import { StudentCreateProjectDto } from './dto/student-create-project.dto';
import { StudentUpdateOwnProjectDto } from './dto/student-update-own-project.dto';
import { TeamEnrollmentSettingsDto } from './dto/team-enrollment-settings.dto';
import { UpdateProjectDto } from './dto/update-project.dto';

function mapSupervisors(dto: CreateProjectDto | UpdateProjectDto) {
  const ids = (dto.supervisorIds ?? [])
    .filter(Boolean)
    .map((id) => new Types.ObjectId(id));
  const primary =
    dto.supervisor != null && dto.supervisor !== ''
      ? new Types.ObjectId(String(dto.supervisor))
      : ids[0] ?? null;
  return { supervisors: ids, supervisor: primary };
}

function mongoRefToIdString(ref: unknown): string {
  if (ref == null) {
    return '';
  }
  if (typeof ref === 'object' && ref !== null && '_id' in ref) {
    return String((ref as { _id: Types.ObjectId | string })._id);
  }
  return String(ref);
}

/** شكل موحّد: `YYYY-(Y+1)` مثل 2025-2026 (يقبل `/` أو مسافات أو فاصلة عربية بين السنتين). */
function normalizeAcademicYearRange(input: string): string {
  const s = input
    .trim()
    .replace(/\s+/g, '')
    .replace(/\u2212/g, '-')
    .replace(/[\u060C\u066B\u061B,/،]+/g, '-');
  const m = /^(\d{4})\D+(\d{4})$/.exec(s);
  if (!m) {
    throw new BadRequestException(
      'العام الدراسي يجب أن يكون بالشكل سنة-سنة التالية (مثل 2025-2026).',
    );
  }
  const a = Number(m[1]);
  const b = Number(m[2]);
  if (!Number.isFinite(a) || !Number.isFinite(b) || b !== a + 1) {
    throw new BadRequestException(
      'العام الدراسي غير صالح: سنة الثانية يجب أن تكون أول سنة + 1.',
    );
  }
  return `${a}-${b}`;
}

@Injectable()
export class ProjectsService {
  constructor(
    @InjectModel(Project.name) private readonly model: Model<Project>,
    @InjectModel(Student.name) private readonly students: Model<Student>,
    @InjectModel(CommitteeDoctor.name)
    private readonly committeeDoctors: Model<CommitteeDoctor>,
    @InjectModel(JoinRequest.name) private readonly joinRequests: Model<JoinRequest>,
    @InjectModel(PeerTeamJoinRequest.name)
    private readonly peerJoins: Model<PeerTeamJoinRequest>,
    @InjectModel(SupervisionInvitation.name)
    private readonly supervisionInvites: Model<SupervisionInvitation>,
    @InjectModel(Session.name) private readonly sessions: Model<Session>,
    @InjectModel(Blacklist.name) private readonly blacklist: Model<Blacklist>,
  ) {}

  create(dto: CreateProjectDto) {
    const { supervisors, supervisor } = mapSupervisors(dto);
    return this.model.create({
      title: dto.title,
      description: dto.description,
      academicYear: normalizeAcademicYearRange(dto.academicYear.trim()),
      isFinished: dto.isFinished ?? false,
      mark: dto.mark ?? 0,
      committees: dto.committees ? new Types.ObjectId(dto.committees) : null,
      createdByStudent: null,
      supervisors,
      supervisor,
      supervisorDisplayName: dto.supervisorDisplayName,
      enrollmentOpen: true,
      maxTeamMembers: null,
    });
  }

  /** UML: Student → Create Projects */
  async createMine(studentId: string, dto: StudentCreateProjectDto) {
    const st = await this.students.findById(studentId).exec();
    if (!st) {
      throw new NotFoundException('الطالب غير موجود');
    }
    if (st.project) {
      throw new ConflictException('مسجَّل بطريق مشروع واحد؛ أنشِئ مشروعك عند غياب تسجيل سابق.');
    }

    const created = await this.model.create({
      title: dto.title.trim(),
      description: dto.description.trim(),
      academicYear: normalizeAcademicYearRange(dto.academicYear.trim()),
      isFinished: false,
      mark: 0,
      committees: null,
      createdByStudent: new Types.ObjectId(studentId),
      supervisors: [],
      supervisor: null,
      supervisorDisplayName: undefined,
      enrollmentOpen: true,
      maxTeamMembers: 2,
    });

    await this.students.findByIdAndUpdate(studentId, {
      $set: { project: created._id },
    });

    return this.findOne(String(created._id));
  }

  findAll() {
    return this.model
      .find()
      .populate('supervisor', '-password')
      .populate('supervisors', '-password')
      .populate('committees')
      .populate('createdByStudent', '-password')
      .sort({ academicYear: -1, title: 1 })
      .lean()
      .exec();
  }

  /** قائد فريق طالب: إغلاق أو فتح الانتساب، وتعديل السقف العددي. */
  async updateTeamEnrollmentForOwner(
    ownerStudentId: string,
    projectId: string,
    dto: TeamEnrollmentSettingsDto,
  ) {
    const p = await this.model.findById(projectId).exec();
    if (!p) {
      throw new NotFoundException('المشروع غير موجود');
    }
    if (!p.createdByStudent || String(p.createdByStudent) !== ownerStudentId) {
      throw new ForbiddenException(
        'يمكن تعديل إعدادات الفريق فقط لمشروع أنشأته بنفسك.',
      );
    }
    const patch: Record<string, unknown> = {};
    if (dto.enrollmentOpen !== undefined) {
      patch.enrollmentOpen = dto.enrollmentOpen;
    }
    if (dto.maxTeamMembers !== undefined) {
      patch.maxTeamMembers = dto.maxTeamMembers;
    }
    if (!Object.keys(patch).length) {
      return this.findOne(projectId);
    }
    const doc = await this.model
      .findByIdAndUpdate(projectId, { $set: patch }, { new: true })
      .populate('supervisor', '-password')
      .populate('supervisors', '-password')
      .populate('committees')
      .populate('createdByStudent', '-password')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Project not found');
    }
    return doc;
  }

  /** الطالب يعدّل عنوان/وصف/عام مشروع أنشأه بنفسه. */
  async updateMineContent(
    studentId: string,
    projectId: string,
    dto: StudentUpdateOwnProjectDto,
  ) {
    const st = await this.students.findById(studentId).exec();
    if (!st?.project || String(st.project) !== projectId) {
      throw new ForbiddenException('هذا ليس مشروعك الحالي المسجَّل.');
    }
    const p = await this.model.findById(projectId).exec();
    if (!p) {
      throw new NotFoundException('المشروع غير موجود');
    }
    if (!p.createdByStudent || String(p.createdByStudent) !== studentId) {
      throw new ForbiddenException(
        'يمكن التعديل هنا فقط لمشروع أنت منشئه (قائد الفريق).',
      );
    }
    if (p.isFinished === true) {
      throw new BadRequestException('مشروع منجز — لا يمكن تعديل البيانات الأساسية.');
    }
    const doc = await this.model
      .findByIdAndUpdate(
        projectId,
        {
          $set: {
            title: dto.title.trim(),
            description: dto.description.trim(),
            academicYear: normalizeAcademicYearRange(dto.academicYear.trim()),
          },
        },
        { new: true },
      )
      .populate('supervisor', '-password')
      .populate('supervisors', '-password')
      .populate('committees')
      .populate('createdByStudent', '-password')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Project not found');
    }
    return doc;
  }

  /**
   * حذف مشروع أنشأه الطالب ولم يكن عليه أي عضو سواه (فريق شخصي قبل انضمام الآخرين).
   */
  async deleteMineProject(studentId: string, projectId: string) {
    const st = await this.students.findById(studentId).exec();
    if (!st?.project || String(st.project) !== projectId) {
      throw new ForbiddenException('هذا ليس مشروعك الحالي المسجَّل.');
    }
    const p = await this.model.findById(projectId).exec();
    if (!p) {
      throw new NotFoundException('المشروع غير موجود');
    }
    if (!p.createdByStudent || String(p.createdByStudent) !== studentId) {
      throw new ForbiddenException('يمكن الحذف فقط لمشروع أنت أنشأته.');
    }
    const memberCount = await this.students.countDocuments({
      project: new Types.ObjectId(projectId),
    });
    if (memberCount !== 1) {
      throw new ConflictException(
        'لا يمكن حذف المشروع وفيه أكثر من طالب — انسحاب الأعضاء غير مدعوم عبر هذا الأمر بعد.',
      );
    }
    const pid = new Types.ObjectId(projectId);
    await this.joinRequests.deleteMany({ project: pid }).exec();
    await this.peerJoins.deleteMany({ project: pid }).exec();
    await this.supervisionInvites.deleteMany({ project: pid }).exec();
    await this.blacklist.deleteMany({ project: pid }).exec();
    await this.sessions.deleteMany({ project: pid }).exec();
    await this.students.updateMany({ project: pid }, { $set: { project: null } });
    await this.model.findByIdAndDelete(projectId).exec();
    return { deleted: true };
  }

  async findOne(id: string) {
    const doc = await this.model
      .findById(id)
      .populate('supervisor', '-password')
      .populate('supervisors', '-password')
      .populate('committees')
      .populate('createdByStudent', '-password')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Project not found');
    }
    const pid = new Types.ObjectId(id);
    const members = await this.students
      .find({ project: pid })
      .select('name uniNumber')
      .sort({ name: 1 })
      .lean()
      .exec();

    const creatorId = mongoRefToIdString(doc.createdByStudent);
    const teamStudents = members
      .map((m) => ({
        name: m.name,
        uniNumber: m.uniNumber,
        isTeamLeader: Boolean(creatorId && String(m._id) === creatorId),
      }))
      .sort((a, b) => {
        if (a.isTeamLeader !== b.isTeamLeader) {
          return a.isTeamLeader ? -1 : 1;
        }
        return a.name.localeCompare(b.name, 'ar');
      });

    return { ...doc, teamStudents };
  }

  async update(id: string, dto: UpdateProjectDto) {
    const patch: Record<string, unknown> = {
      title: dto.title,
      description: dto.description,
      academicYear:
        dto.academicYear === undefined
          ? undefined
          : normalizeAcademicYearRange(String(dto.academicYear).trim()),
      isFinished: dto.isFinished,
      mark: dto.mark,
      supervisorDisplayName: dto.supervisorDisplayName,
    };
    for (const k of Object.keys(patch)) {
      if (patch[k] === undefined) {
        delete patch[k];
      }
    }
    if (dto.committees !== undefined) {
      patch.committees =
        dto.committees == null || dto.committees === ''
          ? null
          : new Types.ObjectId(dto.committees);
    }
    if (dto.supervisorIds !== undefined || dto.supervisor !== undefined) {
      const { supervisors, supervisor } = mapSupervisors(dto);
      patch.supervisors = supervisors;
      patch.supervisor = supervisor;
    }
    const doc = await this.model
      .findByIdAndUpdate(id, patch, { new: true })
      .populate('supervisor', '-password')
      .populate('supervisors', '-password')
      .populate('committees')
      .populate('createdByStudent', '-password')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Project not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Project not found');
    }
    return { deleted: true };
  }

  /** عضو من لجنة المشروع المُجمَّع له يحدد العلامة النهائية بعد المناقشة. */
  async setDefenseFinalMark(actorDoctorId: string, projectId: string, dto: DefenseFinalMarkDto) {
    const p = await this.model.findById(projectId).exec();
    if (!p) {
      throw new NotFoundException('المشروع غير موجود');
    }
    if (!p.committees) {
      throw new BadRequestException(
        'لم يُعيَّن للمشروع لجنة من الإدارة بعد — لا يمكن تسجيل علامة لجنة.',
      );
    }
    const cid = String(p.committees);
    const inCommittee = await this.committeeDoctors.exists({
      committees: new Types.ObjectId(cid),
      doctor: new Types.ObjectId(actorDoctorId),
    });
    if (!inCommittee) {
      throw new ForbiddenException('لست ضمن هذه اللجنة وفق السجلات');
    }
    const doc = await this.model
      .findByIdAndUpdate(projectId, { mark: dto.mark }, { new: true })
      .populate('supervisor', '-password')
      .populate('supervisors', '-password')
      .populate('committees')
      .populate('createdByStudent', '-password')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Project not found');
    }
    return doc;
  }
}
