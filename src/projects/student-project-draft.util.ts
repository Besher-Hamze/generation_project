import { Types } from 'mongoose';

/**
 * مشروع شخصي لم يُعيَّن له مشرف بعد — يمكن للطالب رفعه كمسودة
 * وفي الوقت نفسه أن يطرح طلبات انضمام على مشاريع يشرف عليها أساتذة.
 */
export type ProjectLeanWithSupervisionFields = {
  _id?: Types.ObjectId | string;
  createdByStudent?: Types.ObjectId | string | null;
  supervisor?: Types.ObjectId | string | null;
  supervisors?: unknown[] | null;
};

export function isSoloUnsupervisedStudentDraftProject(
  studentId: string,
  project?: ProjectLeanWithSupervisionFields | null,
): boolean {
  if (!project || typeof project !== 'object') {
    return false;
  }
  if (!project.createdByStudent) {
    return false;
  }
  if (String(project.createdByStudent) !== String(studentId)) {
    return false;
  }
  if (project.supervisor) {
    return false;
  }
  const coc = Array.isArray(project.supervisors) ? project.supervisors.length : 0;
  if (coc > 0) {
    return false;
  }
  return true;
}
