import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Department } from '../schemas/department.schema';
import { Project } from '../schemas/project.schema';
import { RegistrationOrder } from '../schemas/registration-order.schema';
import { Student } from '../schemas/student.schema';
import { CreateStudentDto } from './dto/create-student.dto';
import { UpdateStudentDto } from './dto/update-student.dto';

@Injectable()
export class StudentsService {
  constructor(
    @InjectModel(Student.name) private readonly model: Model<Student>,
    @InjectModel(Department.name) private readonly departments: Model<Department>,
    @InjectModel(Project.name) private readonly projects: Model<Project>,
    @InjectModel(RegistrationOrder.name)
    private readonly orders: Model<RegistrationOrder>,
  ) {}

  async create(dto: CreateStudentDto) {
    await this.assertRefs({
      department: dto.department,
      project: dto.project ?? null,
      registrationOrder: dto.registrationOrder ?? null,
    });
    const exists = await this.model.exists({ uniNumber: dto.uniNumber.trim() });
    if (exists) {
      throw new ConflictException('University number already exists');
    }
    return this.model.create({
      uniNumber: dto.uniNumber.trim(),
      name: dto.name.trim(),
      password: dto.password,
      registrationOrder: dto.registrationOrder ?? null,
      department: dto.department,
      project: dto.project ?? null,
    });
  }

  private async assertRefs(dto: {
    department: string;
    project?: string | null;
    registrationOrder?: string | null;
  }) {
    const d = await this.departments.findById(dto.department).exec();
    if (!d) {
      throw new NotFoundException('Department not found');
    }
    if (dto.registrationOrder) {
      const o = await this.orders.findById(dto.registrationOrder).exec();
      if (!o) {
        throw new NotFoundException('Registration order not found');
      }
    }
    if (dto.project) {
      const p = await this.projects.findById(dto.project).exec();
      if (!p) {
        throw new NotFoundException('Project not found');
      }
    }
  }

  findAll() {
    return this.model
      .find()
      .select('-password')
      .populate('department')
      .populate('project')
      .populate('registrationOrder')
      .sort({ uniNumber: 1 })
      .lean()
      .exec();
  }

  async findOne(id: string) {
    const doc = await this.model
      .findById(id)
      .select('-password')
      .populate('department')
      .populate('project')
      .populate('registrationOrder')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Student not found');
    }
    return doc;
  }

  async update(id: string, dto: UpdateStudentDto) {
    if (dto.department || dto.project || dto.registrationOrder) {
      const cur = await this.model.findById(id).lean().exec();
      if (!cur) {
        throw new NotFoundException('Student not found');
      }
      await this.assertRefs({
        department: dto.department ?? String(cur.department),
        project:
          dto.project !== undefined ? dto.project : cur.project
            ? String(cur.project)
            : null,
        registrationOrder:
          dto.registrationOrder ??
          (cur.registrationOrder != null
            ? String(cur.registrationOrder)
            : undefined),
      });
    }
    if (dto.uniNumber) {
      const clash = await this.model
        .findOne({ uniNumber: dto.uniNumber.trim(), _id: { $ne: id } })
        .exec();
      if (clash) {
        throw new ConflictException('University number already in use');
      }
    }
    const patch: Record<string, unknown> = { ...dto };
    if (dto.uniNumber) {
      patch.uniNumber = dto.uniNumber.trim();
    }
    if (dto.name) {
      patch.name = dto.name.trim();
    }
    const doc = await this.model
      .findByIdAndUpdate(id, patch, { new: true })
      .select('-password')
      .populate('department')
      .populate('project')
      .populate('registrationOrder')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Student not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Student not found');
    }
    return { deleted: true };
  }
}
