import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { SystemSetting } from '../schemas/system-setting.schema';

@Injectable()
export class SystemSettingsService {
  constructor(
    @InjectModel(SystemSetting.name)
    private readonly model: Model<SystemSetting>,
  ) {}

  async upsert(key: string, value: string, description?: string) {
    return this.model
      .findOneAndUpdate(
        { key: key.trim() },
        { key: key.trim(), value, description },
        { upsert: true, new: true },
      )
      .lean()
      .exec();
  }

  findAll() {
    return this.model.find().sort({ key: 1 }).lean().exec();
  }

  async findByKey(key: string) {
    const doc = await this.model.findOne({ key }).lean().exec();
    if (!doc) {
      throw new NotFoundException('لم يتم العثور على المفتاح');
    }
    return doc;
  }

  async updateValue(key: string, value: string) {
    const doc = await this.model
      .findOneAndUpdate({ key }, { value }, { new: true })
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('لم يتم العثور على المفتاح');
    }
    return doc;
  }

  async remove(key: string) {
    const res = await this.model.findOneAndDelete({ key }).exec();
    if (!res) {
      throw new NotFoundException('لم يتم العثور على المفتاح');
    }
    return { deleted: true };
  }
}
