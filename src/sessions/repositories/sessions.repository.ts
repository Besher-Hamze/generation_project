import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';
import { Session } from '../../schemas/session.schema';

@Injectable()
export class SessionsRepository {
  constructor(
    @InjectModel(Session.name) private readonly model: Model<Session>,
  ) {}

  insertOne(data: Record<string, unknown>) {
    return this.model.create(data);
  }

  findById(id: string) {
    return this.model.findById(id).exec();
  }

  findByIdLeanPopulated(id: string) {
    return this.model
      .findById(id)
      .populate('project')
      .populate('doctor', '-password')
      .lean()
      .exec();
  }

  findMany(filter: FilterQuery<Session>) {
    return this.model
      .find(filter)
      .populate('project')
      .populate('doctor', '-password')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  updateById(id: string, patch: Record<string, unknown>) {
    return this.model
      .findByIdAndUpdate(id, patch, { new: true })
      .populate('project')
      .populate('doctor', '-password')
      .lean()
      .exec();
  }

  deleteById(id: string) {
    return this.model.findByIdAndDelete(id).exec();
  }
}
