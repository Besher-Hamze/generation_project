import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { RegistrationOrder } from '../schemas/registration-order.schema';
import { CreateRegistrationOrderDto } from './dto/create-registration-order.dto';
import { UpdateRegistrationOrderDto } from './dto/update-registration-order.dto';

@Injectable()
export class RegistrationOrdersService {
  constructor(
    @InjectModel(RegistrationOrder.name)
    private readonly model: Model<RegistrationOrder>,
  ) {}

  create(dto: CreateRegistrationOrderDto) {
    return this.model.create({
      orderStart: new Date(dto.orderStart),
      orderStatus: dto.orderStatus,
    });
  }

  findAll() {
    return this.model.find().sort({ orderStart: -1 }).lean().exec();
  }

  async findOne(id: string) {
    const doc = await this.model.findById(id).lean().exec();
    if (!doc) {
      throw new NotFoundException('Registration order not found');
    }
    return doc;
  }

  async update(id: string, dto: UpdateRegistrationOrderDto) {
    const patch: Record<string, unknown> = { ...dto };
    if (dto.orderStart) {
      patch.orderStart = new Date(dto.orderStart);
    }
    const doc = await this.model
      .findByIdAndUpdate(id, patch, { new: true })
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Registration order not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Registration order not found');
    }
    return { deleted: true };
  }
}
