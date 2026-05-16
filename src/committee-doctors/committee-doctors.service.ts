import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CommitteeDoctor } from '../schemas/committee-doctor.schema';
import { Committees } from '../schemas/committees.schema';
import { Doctor } from '../schemas/doctor.schema';
import { CreateCommitteeDoctorDto } from './dto/create-committee-doctor.dto';
import { UpdateCommitteeDoctorDto } from './dto/update-committee-doctor.dto';

@Injectable()
export class CommitteeDoctorsService {
  constructor(
    @InjectModel(CommitteeDoctor.name)
    private readonly model: Model<CommitteeDoctor>,
    @InjectModel(Committees.name) private readonly committees: Model<Committees>,
    @InjectModel(Doctor.name) private readonly doctors: Model<Doctor>,
  ) {}

  async create(dto: CreateCommitteeDoctorDto) {
    const c = await this.committees.findById(dto.committees).exec();
    if (!c) {
      throw new NotFoundException('Committee not found');
    }
    const d = await this.doctors.findById(dto.doctor).exec();
    if (!d) {
      throw new NotFoundException('Doctor not found');
    }
    return this.model.create(dto);
  }

  findAll() {
    return this.model
      .find()
      .populate('committees')
      .populate('doctor', '-password')
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async findOne(id: string) {
    const doc = await this.model
      .findById(id)
      .populate('committees')
      .populate('doctor', '-password')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Committee doctor link not found');
    }
    return doc;
  }

  async update(id: string, dto: UpdateCommitteeDoctorDto) {
    if (dto.committees) {
      const c = await this.committees.findById(dto.committees).exec();
      if (!c) {
        throw new NotFoundException('Committee not found');
      }
    }
    if (dto.doctor) {
      const d = await this.doctors.findById(dto.doctor).exec();
      if (!d) {
        throw new NotFoundException('Doctor not found');
      }
    }
    const doc = await this.model
      .findByIdAndUpdate(id, dto, { new: true })
      .populate('committees')
      .populate('doctor', '-password')
      .lean()
      .exec();
    if (!doc) {
      throw new NotFoundException('Committee doctor link not found');
    }
    return doc;
  }

  async remove(id: string) {
    const res = await this.model.findByIdAndDelete(id).exec();
    if (!res) {
      throw new NotFoundException('Committee doctor link not found');
    }
    return { deleted: true };
  }
}
