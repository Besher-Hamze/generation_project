import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Blacklist } from '../schemas/blacklist.schema';
import { Project } from '../schemas/project.schema';
import { Student } from '../schemas/student.schema';
import { CreateBlacklistDto } from './dto/create-blacklist.dto';
import { UpdateBlacklistDto } from './dto/update-blacklist.dto';

@Injectable()
export class BlacklistsService {
  constructor(
    @InjectModel(Blacklist.name) private readonly model: Model<Blacklist>,
    @InjectModel(Student.name) private readonly students: Model<Student>,
    @InjectModel(Project.name) private readonly projects: Model<Project>,
  ) {}

  async create(dto: CreateBlacklistDto) {
    const s = await this.students.findById(dto.student).exec();
    if (!s) {
      throw new NotFoundException('Student not found');
    }
    const p = await this.projects.findById(dto.project).exec();
    if (!p) {
      throw new NotFoundException('Project not found');
    }
    return this.model.create(dto);
  }

  findAll() {
    return this.model
      .find()
      .populate('student', '-password')
      .populate('project')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async findOne(id: string) {
    const doc = await this.model
      .findById(id)
      .populate('student', '-password')
      .populate('project')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Blacklist entry not found');
    }
    return doc;
  }

  async update(id: string, dto: UpdateBlacklistDto) {
    if (dto.student) {
      const s = await this.students.findById(dto.student).exec();
      if (!s) {
        throw new NotFoundException('Student not found');
      }
    }
    if (dto.project) {
      const p = await this.projects.findById(dto.project).exec();
      if (!p) {
        throw new NotFoundException('Project not found');
      }
    }
    const doc = await this.model
      .findByIdAndUpdate(id, dto, { new: true })
      .populate('student', '-password')
      .populate('project')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Blacklist entry not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Blacklist entry not found');
    }
    return { deleted: true };
  }
}
