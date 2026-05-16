import { Controller, Get } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Department } from '../schemas/department.schema';
import { Doctor } from '../schemas/doctor.schema';
import { Project } from '../schemas/project.schema';
import { RegistrationOrder } from '../schemas/registration-order.schema';

/** بيانات التسجيل العامة بدون JWT — للتطبيق المحمول فقط. */
@Controller('public')
export class PublicController {
  constructor(
    @InjectModel(Department.name)
    private readonly departmentModel: Model<Department>,
    @InjectModel(RegistrationOrder.name)
    private readonly registrationOrderModel: Model<RegistrationOrder>,
    @InjectModel(Project.name)
    private readonly projectModel: Model<Project>,
    @InjectModel(Doctor.name)
    private readonly doctorModel: Model<Doctor>,
  ) {}

  @Get('departments')
  listDepartments() {
    return this.departmentModel
      .find()
      .select('_id name')
      .sort({ name: 1 })
      .lean()
      .exec();
  }

  @Get('registration-orders')
  listRegistrationOrders() {
    return this.registrationOrderModel
      .find()
      .select('_id orderStart orderStatus')
      .sort({ orderStart: -1 })
      .lean()
      .exec();
  }

  @Get('doctors')
  listDoctors() {
    return this.doctorModel
      .find()
      .select('name email department')
      .populate('department', 'name')
      .sort({ name: 1 })
      .limit(800)
      .lean()
      .exec();
  }

  @Get('projects')
  listProjects() {
    return this.projectModel
      .find()
      .select('_id title academicYear description')
      .sort({ academicYear: -1, title: 1 })
      .limit(500)
      .lean()
      .exec();
  }
}
