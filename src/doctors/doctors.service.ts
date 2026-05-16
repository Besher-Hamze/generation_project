import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Department } from '../schemas/department.schema';
import { Doctor } from '../schemas/doctor.schema';
import { CreateDoctorDto } from './dto/create-doctor.dto';
import { UpdateDoctorDto } from './dto/update-doctor.dto';

@Injectable()
export class DoctorsService {
  constructor(
    @InjectModel(Doctor.name) private readonly model: Model<Doctor>,
    @InjectModel(Department.name) private readonly departments: Model<Department>,
  ) {}

  async create(dto: CreateDoctorDto) {
    const dep = await this.departments.findById(dto.department).exec();
    if (!dep) {
      throw new NotFoundException('Department not found');
    }
    const exists = await this.model.exists({
      email: dto.email.toLowerCase(),
    });
    if (exists) {
      throw new ConflictException('Email already registered');
    }
    return this.model.create({
      ...dto,
      email: dto.email.toLowerCase(),
    });
  }

  findAll() {
    return this.model
      .find()
      .select('-password')
      .populate('department')
      .sort({ name: 1 })
      .lean()
      .exec();
  }

  async findOne(id: string) {
    const doc = await this.model
      .findById(id)
      .select('-password')
      .populate('department')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Doctor not found');
    }
    return doc;
  }

  async update(id: string, dto: UpdateDoctorDto) {
    if (dto.department) {
      const dep = await this.departments.findById(dto.department).exec();
      if (!dep) {
        throw new NotFoundException('Department not found');
      }
    }
    if (dto.email) {
      const clash = await this.model
        .findOne({
          email: dto.email.toLowerCase(),
          _id: { $ne: id },
        })
        .exec();
      if (clash) {
        throw new ConflictException('Email already in use');
      }
    }
    const patch: Record<string, unknown> = { ...dto };
    if (dto.email) {
      patch.email = dto.email.toLowerCase();
    }
    const doc = await this.model
      .findByIdAndUpdate(id, patch, { new: true })
      .select('-password')
      .populate('department')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Doctor not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Doctor not found');
    }
    return { deleted: true };
  }
}
