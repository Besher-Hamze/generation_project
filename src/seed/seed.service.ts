import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { createHash } from 'crypto';
import { parse } from 'csv-parse/sync';
import { existsSync, readFileSync } from 'fs';
import { HydratedDocument, Model, Types } from 'mongoose';
import { join } from 'path';
import { normalizeArabicNameKey } from '../common/arabic-name-key';
import { hashPassword } from '../common/password.util';
import { Department } from '../schemas/department.schema';
import { Doctor } from '../schemas/doctor.schema';
import { Project } from '../schemas/project.schema';
import { Admin } from '../schemas/admin.schema';

const COL_SUPERVISOR = 'الدكتور المشرف';
const COL_YEAR = 'العام الدراسي';
const COL_TITLE = 'اسم المشروع';
const COL_DESC = 'وصف المشروع';

function normalizeAcademicYear(raw: string): string {
  return raw
    .replace(/\s+/g, '')
    .replace(/_/g, '-')
    .replace(/-{2,}/g, '-');
}

function seedEmailForDoctor(nameKey: string, departmentId: string): string {
  const h = createHash('sha256')
    .update(`${departmentId}|${nameKey}`)
    .digest('hex')
    .slice(0, 4);
  return `doctor.${h}@seed.local`;
}

/** Co-supervisors separated by `_`, `-`, en dash, or em dash. */
function splitSupervisorNames(raw: string): string[] {
  return raw
    .split(/[_\-\u2013\u2014]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

export interface SeedResult {
  projectsCreated: number;
  doctorsCreated: number;
  rowsSkipped: number;
}

@Injectable()
export class SeedService {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    @InjectModel(Department.name)
    private readonly departmentModel: Model<Department>,
    @InjectModel(Doctor.name)
    private readonly doctorModel: Model<Doctor>,
    @InjectModel(Project.name)
    private readonly projectModel: Model<Project>,
    @InjectModel(Admin.name)
    private readonly adminModel: Model<Admin>,
  ) {}

  async run(csvPath?: string): Promise<SeedResult> {
    const path =
      csvPath ??
      process.env.SEED_CSV_PATH ??
      join(process.cwd(), 'merged.csv');

    if (!existsSync(path)) {
      throw new Error(
        `CSV not found: ${path}. Set SEED_CSV_PATH or place merged.csv in project root.`,
      );
    }

    const text = readFileSync(path, 'utf8');
    const records = parse(text, {
      columns: true,
      skip_empty_lines: true,
      bom: true,
      relax_column_count: true,
    }) as Record<string, string>[];

    const defaultDeptName =
      process.env.SEED_DEFAULT_DEPARTMENT ?? 'قسم الحواسيب';
    let dept = await this.departmentModel.findOne({
      name: defaultDeptName,
    });
    if (!dept) {
      dept = await this.departmentModel.create({ name: defaultDeptName });
    }
    const departmentId = dept._id.toString();

    const doctorPasswordPlain = process.env.SEED_DOCTOR_PASSWORD ?? '123456';
    const doctorPasswordHash = await hashPassword(doctorPasswordPlain);
    const placeholderOffice = process.env.SEED_DOCTOR_OFFICE ?? '—';
    const placeholderPhone = process.env.SEED_DOCTOR_PHONE ?? '—';

    let projectsCreated = 0;
    let doctorsCreated = 0;
    let rowsSkipped = 0;

    const doctorCache = new Map<string, HydratedDocument<Doctor>>();

    for (const row of records) {
      const supervisorRaw = (row[COL_SUPERVISOR] ?? '').trim();
      const yearRaw = (row[COL_YEAR] ?? '').trim();
      const title = (row[COL_TITLE] ?? '').trim();
      const description = (row[COL_DESC] ?? '').trim();

      if (!title && !description && !supervisorRaw && !yearRaw) {
        rowsSkipped++;
        continue;
      }
      if (!title) {
        rowsSkipped++;
        continue;
      }

      const academicYear = yearRaw ? normalizeAcademicYear(yearRaw) : '';

      const supervisorIds: Types.ObjectId[] = [];
      let supervisorDisplay: string | undefined;

      if (supervisorRaw) {
        supervisorDisplay = supervisorRaw;
        let names = splitSupervisorNames(supervisorRaw);
        if (names.length === 0 && supervisorRaw.trim().length > 0) {
          names = [supervisorRaw.trim()];
        }

        for (const doctorName of names) {
          const nameKey = normalizeArabicNameKey(doctorName);
          if (!nameKey) {
            continue;
          }
          const cacheKey = `${departmentId}:${nameKey}`;
          let doc = doctorCache.get(cacheKey);
          if (!doc) {
            doc =
              (await this.doctorModel.findOne({
                department: dept._id,
                nameKey,
              })) ?? undefined;
          }
          if (!doc) {
            const email = seedEmailForDoctor(nameKey, departmentId);
            doc = await this.doctorModel.create({
              name: doctorName.trim(),
              nameKey,
              email,
              password: doctorPasswordHash,
              officeNo: placeholderOffice,
              phone: placeholderPhone,
              department: dept._id,
            });
            doctorsCreated++;
          }
          doctorCache.set(cacheKey, doc);
          supervisorIds.push(doc._id);
        }
      }

      const primarySupervisor = supervisorIds[0] ?? null;

      await this.projectModel.create({
        title,
        description: description || title,
        academicYear: academicYear || 'غير محدد',
        isFinished: false,
        committees: null,
        mark: 0,
        createdByStudent: null,
        supervisor: primarySupervisor,
        supervisors: supervisorIds,
        supervisorDisplayName: supervisorDisplay,
      });
      projectsCreated++;
    }

    this.logger.log(
      `Seed done: projects=${projectsCreated}, newDoctors=${doctorsCreated}, skippedRows=${rowsSkipped}`,
    );

    await this.ensureBootstrapAdmin();

    return { projectsCreated, doctorsCreated, rowsSkipped };
  }

  private async ensureBootstrapAdmin(): Promise<void> {
    const email = (process.env.ADMIN_EMAIL ?? 'admin@grad.local').toLowerCase();
    const passwordPlain = process.env.ADMIN_PASSWORD ?? 'admin123';
    const name = process.env.ADMIN_NAME ?? 'مشرف النظام';

    const exists = await this.adminModel.exists({ email });
    if (exists) {
      return;
    }
    await this.adminModel.create({
      name,
      email,
      password: passwordPlain,
    });
    this.logger.log(`Created bootstrap admin account: ${email}`);
  }
}
