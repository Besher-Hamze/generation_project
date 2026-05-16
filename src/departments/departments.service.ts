import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Department } from '../schemas/department.schema';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@Injectable()
export class DepartmentsService {
  constructor(
    @InjectModel(Department.name) private readonly model: Model<Department>,
  ) {}

  create(dto: CreateDepartmentDto) {
    return this.model.create(dto);
  }

  findAll() {
    return this.model.find().sort({ name: 1 }).lean().exec();
  }

  async findOne(id: string) {
    const doc = await this.model.findById(id).lean().exec();
    if (!doc) {
      throw new NotFoundException('Department not found');
    }
    return doc;
  }

  async update(id: string, dto: UpdateDepartmentDto) {
    const doc = await this.model
      .findByIdAndUpdate(id, dto, { new: true })
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Department not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Department not found');
    }
    return { deleted: true };
  }
}
