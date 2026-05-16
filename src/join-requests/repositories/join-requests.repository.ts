import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ClientSession, Model, Types } from 'mongoose';
import {
  JoinRequest,
  JoinRequestStatus,
} from '../../schemas/join-request.schema';

@Injectable()
export class JoinRequestsRepository {
  constructor(
    @InjectModel(JoinRequest.name)
    private readonly model: Model<JoinRequest>,
  ) {}

  create(
    data: {
      requester: Types.ObjectId;
      project: Types.ObjectId;
      targetStudent?: Types.ObjectId | null;
    },
    session?: ClientSession,
  ) {
    const doc = new this.model({
      ...data,
      targetStudent: data.targetStudent ?? null,
      status: 'pending' as JoinRequestStatus,
    });
    return session ? doc.save({ session }) : doc.save();
  }

  findById(id: string) {
    return this.model.findById(id).exec();
  }

  findPendingForRequesterProject(
    requesterId: Types.ObjectId,
    projectId: Types.ObjectId,
  ) {
    return this.model
      .findOne({
        requester: requesterId,
        project: projectId,
        status: 'pending',
      })
      .exec();
  }

  countRejectionsForRequesterOnProject(
    requesterId: Types.ObjectId,
    projectId: Types.ObjectId,
  ) {
    return this.model.countDocuments({
      requester: requesterId,
      project: projectId,
      status: 'rejected',
    });
  }

  listOutgoingForStudent(requesterId: string) {
    return this.model
      .find({ requester: requesterId })
      .populate('targetStudent', '-password')
      .populate({
        path: 'project',
        populate: [
          { path: 'supervisor', select: 'name email' },
          { path: 'supervisors', select: 'name email' },
        ],
      })
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  findPopulatedById(id: string) {
    return this.model
      .findById(id)
      .populate('requester', '-password')
      .populate('targetStudent', '-password')
      .populate({
        path: 'project',
        populate: [
          { path: 'supervisor', select: 'name email' },
          { path: 'supervisors', select: 'name email' },
        ],
      })
      .lean()
      .exec();
  }
  /** بعد قبول طلب واحد؛ إلغاء باقي الطلبات المعلّقة لذات الطالب. */
  rejectOtherPendingForStudent(
    requesterId: Types.ObjectId,
    exceptJoinRequestId: Types.ObjectId,
  ) {
    return this.model
      .updateMany(
        {
          requester: requesterId,
          status: 'pending',
          _id: { $ne: exceptJoinRequestId },
        },
        { $set: { status: 'cancelled' } },
      )
      .exec();
  }

  listPendingForProjects(projectIds: Types.ObjectId[]) {
    if (!projectIds.length) {
      return Promise.resolve([]);
    }
    return this.model
      .find({ project: { $in: projectIds }, status: 'pending' })
      .populate('requester', '-password')
      .populate('targetStudent', '-password')
      .populate({
        path: 'project',
        populate: [
          { path: 'supervisor', select: 'name email' },
          { path: 'supervisors', select: 'name email' },
        ],
      })
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }
}
