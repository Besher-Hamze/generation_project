import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { comparePassword } from '../common/password.util';
import {
  isSoloUnsupervisedStudentDraftProject,
  type ProjectLeanWithSupervisionFields,
} from '../projects/student-project-draft.util';
import { Blacklist } from '../schemas/blacklist.schema';
import { Admin } from '../schemas/admin.schema';
import { Doctor } from '../schemas/doctor.schema';
import { Student } from '../schemas/student.schema';
import { AdminLoginDto } from './dto/admin-login.dto';
import { DoctorLoginDto } from './dto/doctor-login.dto';
import { StudentLoginDto } from './dto/student-login.dto';
import { StudentRegisterDto } from './dto/student-register.dto';
import { ChangeDoctorPasswordDto } from './dto/change-doctor-password.dto';
import { JwtPayload } from './jwt.strategy';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(Admin.name) private readonly adminModel: Model<Admin>,
    @InjectModel(Doctor.name) private readonly doctorModel: Model<Doctor>,
    @InjectModel(Student.name) private readonly studentModel: Model<Student>,
    @InjectModel(Blacklist.name) private readonly blacklistModel: Model<Blacklist>,
    private readonly jwt: JwtService,
  ) {}

  private sign(payload: JwtPayload) {
    return this.jwt.sign(payload);
  }

  async adminLogin(dto: AdminLoginDto) {
    const doc = await this.adminModel
      .findOne({ email: dto.email.toLowerCase() })
      .exec();
    if (!doc || !(await comparePassword(dto.password, doc.password))) {
      throw new UnauthorizedException('البريد أو كلمة المرور غير صحيحة');
    }
    const token = this.sign({ sub: String(doc._id), role: 'admin' });
    return {
      accessToken: token,
      role: 'admin' as const,
      user: {
        id: String(doc._id),
        name: doc.name,
        email: doc.email,
      },
    };
  }

  async doctorLogin(dto: DoctorLoginDto) {
    const doc = await this.doctorModel
      .findOne({ email: dto.email.toLowerCase() })
      .exec();
    if (!doc || !(await comparePassword(dto.password, doc.password))) {
      throw new UnauthorizedException('البريد أو كلمة المرور غير صحيحة');
    }
    const token = this.sign({ sub: String(doc._id), role: 'doctor' });
    return {
      accessToken: token,
      role: 'doctor' as const,
      user: {
        id: String(doc._id),
        name: doc.name,
        email: doc.email,
        department: String(doc.department),
      },
    };
  }

  async studentLogin(dto: StudentLoginDto) {
    const doc = await this.studentModel
      .findOne({ uniNumber: dto.uniNumber.trim() })
      .exec();
    if (!doc || !(await comparePassword(dto.password, doc.password))) {
      throw new UnauthorizedException(
        'الرقم الجامعي أو كلمة المرور غير صحيحة',
      );
    }
    const token = this.sign({ sub: String(doc._id), role: 'student' });
    return {
      accessToken: token,
      role: 'student' as const,
      user: {
        id: String(doc._id),
        name: doc.name,
        uniNumber: doc.uniNumber,
        department: String(doc.department),
        project: doc.project ? String(doc.project) : null,
        registrationOrder: doc.registrationOrder
          ? String(doc.registrationOrder)
          : null,
      },
    };
  }

  async studentRegister(dto: StudentRegisterDto) {
    const exists = await this.studentModel.exists({
      uniNumber: dto.uniNumber.trim(),
    });
    if (exists) {
      throw new ConflictException('الرقم الجامعي مسجل مسبقاً');
    }
    const doc = await this.studentModel.create({
      uniNumber: dto.uniNumber.trim(),
      name: dto.name.trim(),
      password: dto.password,
      registrationOrder: dto.registrationOrder
        ? new Types.ObjectId(dto.registrationOrder)
        : null,
      department: dto.department,
      project: dto.project ? new Types.ObjectId(dto.project) : null,
    });
    const token = this.sign({ sub: String(doc._id), role: 'student' });
    return {
      accessToken: token,
      role: 'student' as const,
      user: {
        id: String(doc._id),
        name: doc.name,
        uniNumber: doc.uniNumber,
        department: String(doc.department),
        project: doc.project ? String(doc.project) : null,
        registrationOrder: doc.registrationOrder
          ? String(doc.registrationOrder)
          : null,
      },
    };
  }

  async changeDoctorPassword(
    doctorSub: string,
    dto: ChangeDoctorPasswordDto,
  ) {
    const doc = await this.doctorModel.findById(doctorSub).exec();
    if (!doc) {
      throw new UnauthorizedException();
    }
    if (!(await comparePassword(dto.currentPassword, doc.password))) {
      throw new UnauthorizedException('كلمة المرور الحالية غير صحيحة');
    }
    doc.password = dto.newPassword;
    await doc.save();
    return { updated: true };
  }

  async me(user: JwtPayload) {
    if (user.role === 'admin') {
      const doc = await this.adminModel.findById(user.sub).lean().exec();
      if (!doc) {
        throw new UnauthorizedException();
      }
      const { password: _p, ...rest } = doc;
      return {
        role: 'admin' as const,
        user: { ...rest, id: String(rest._id) },
      };
    }
    if (user.role === 'doctor') {
      const doc = await this.doctorModel.findById(user.sub).lean().exec();
      if (!doc) {
        throw new UnauthorizedException();
      }
      const { password: _p, ...rest } = doc;
      return {
        role: 'doctor' as const,
        user: { ...rest, id: String(rest._id) },
      };
    }
    const docRaw = await this.studentModel
      .findById(user.sub)
      .populate({
        path: 'project',
        select: '_id createdByStudent supervisor supervisors',
      })
      .lean()
      .exec();
    if (!docRaw) {
      throw new UnauthorizedException();
    }

    const pop = docRaw.project as
      | ProjectLeanWithSupervisionFields
      | Types.ObjectId
      | string
      | null
      | undefined;

    let projectId: string | null = null;
    let canRequestJoinToSupervisedProjects = true;
    let canInviteSupervisors = false;

    if (pop == null) {
      projectId = null;
      canRequestJoinToSupervisedProjects = true;
    } else if (typeof pop === 'object' && '_id' in pop) {
      const p = pop as ProjectLeanWithSupervisionFields & { _id: unknown };
      projectId = String(p._id);
      canInviteSupervisors = isSoloUnsupervisedStudentDraftProject(user.sub, p);
      canRequestJoinToSupervisedProjects = canInviteSupervisors;
    } else {
      projectId = String(pop);
      canRequestJoinToSupervisedProjects = false;
    }

    const blockedRows = await this.blacklistModel
      .find({ student: docRaw._id })
      .select('project')
      .lean()
      .exec();
    const blockedProjectIds = blockedRows.map((b) =>
      String(b.project),
    );

    return {
      role: 'student' as const,
      user: {
        id: String(docRaw._id),
        name: docRaw.name,
        uniNumber: docRaw.uniNumber,
        department: String(docRaw.department),
        project: projectId,
        registrationOrder: docRaw.registrationOrder
          ? String(docRaw.registrationOrder)
          : null,
        canRequestJoinToSupervisedProjects,
        canInviteSupervisors,
        blockedProjectIds,
        createdAt: (docRaw as { createdAt?: unknown }).createdAt,
        updatedAt: (docRaw as { updatedAt?: unknown }).updatedAt,
      },
    };
  }
}
