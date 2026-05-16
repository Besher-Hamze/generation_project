import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Committees } from '../schemas/committees.schema';
import { CreateCommitteesDto } from './dto/create-committees.dto';
import { UpdateCommitteesDto } from './dto/update-committees.dto';

@Injectable()
export class CommitteesService {
  constructor(
    @InjectModel(Committees.name) private readonly model: Model<Committees>,
  ) {}

  create(dto: CreateCommitteesDto) {
    const doc: Record<string, unknown> = {};
    if (dto.label !== undefined) {
      doc.label = dto.label;
    }
    if (dto.president !== undefined) {
      doc.president =
        dto.president == null || dto.president === ''
          ? null
          : new Types.ObjectId(dto.president);
    }
    return this.model.create(doc);
  }

  findAll() {
    return this.model.find().sort({ createdAt: -1 }).lean().exec();
  }

  async findOne(id: string) {
    const doc = await this.model.findById(id).lean().exec();
    if (!doc) {
      throw new NotFoundException('Committee not found');
    }
    return doc;
  }

  async update(id: string, dto: UpdateCommitteesDto) {
    const patch: Record<string, unknown> = { ...dto };
    if (dto.president !== undefined) {
      patch.president =
        dto.president == null || dto.president === ''
          ? null
          : new Types.ObjectId(dto.president);
    }
    const doc = await this.model
      .findByIdAndUpdate(id, patch, { new: true })
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Committee not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Committee not found');
    }
    return { deleted: true };
  }
}
