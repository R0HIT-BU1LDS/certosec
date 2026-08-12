const ApiError = require('../utils/ApiError');
const { toStudentJson } = require('../models/student');

/**
 * StudentService contains the student-record business rules. Repositories do
 * the SQL; controllers stay thin; this is where uniqueness and audit logic
 * live.
 */
class StudentService {
  constructor({ studentRepository, auditService }) {
    this.studentRepository = studentRepository;
    this.auditService = auditService;
  }

  async list({ page, pageSize, search, department }) {
    const result = await this.studentRepository.paginate({
      page,
      pageSize,
      search,
      department,
    });
    return {
      items: result.items.map(toStudentJson),
      total: result.total,
      page,
      pageSize,
      totalPages: result.total === 0 ? 0 : Math.ceil(result.total / pageSize),
    };
  }

  async get(id) {
    const row = await this.studentRepository.findById(id);
    if (!row) {
      throw ApiError.notFound('STUDENT_NOT_FOUND', 'Student not found.');
    }
    return toStudentJson(row);
  }

  async create(payload, request) {
    const { studentId, name, email, department, batch, course, phone, profilePhotoUrl } = payload;

    const existingUid = await this.studentRepository.findByStudentUid(studentId);
    if (existingUid) {
      throw ApiError.conflict(
        'STUDENT_UID_EXISTS',
        'A student with that student ID already exists.',
      );
    }
    if (email) {
      const existingEmail = await this.studentRepository.findByEmail(email);
      if (existingEmail) {
        throw ApiError.conflict(
          'STUDENT_EMAIL_EXISTS',
          'A student with that email already exists.',
        );
      }
    }

    const row = await this.studentRepository.create({
      student_uid: studentId,
      full_name: name,
      email: email || null,
      department,
      batch,
      course,
      phone: phone || null,
      profile_photo_url: profilePhotoUrl || null,
      created_by: request.user.id,
    });

    await this.auditService.logRequest(request, {
      action: 'STUDENT_CREATED',
      entityType: 'student',
      entityId: row.id,
    });

    return toStudentJson(row);
  }

  async update(id, payload, request) {
    const existing = await this.studentRepository.findById(id);
    if (!existing) {
      throw ApiError.notFound('STUDENT_NOT_FOUND', 'Student not found.');
    }

    if (payload.studentId && payload.studentId !== existing.student_uid) {
      const existingUid = await this.studentRepository.findByStudentUid(payload.studentId);
      if (existingUid) {
        throw ApiError.conflict(
          'STUDENT_UID_EXISTS',
          'A student with that student ID already exists.',
        );
      }
    }
    if (payload.email && payload.email !== existing.email) {
      const existingEmail = await this.studentRepository.findByEmail(payload.email);
      if (existingEmail) {
        throw ApiError.conflict(
          'STUDENT_EMAIL_EXISTS',
          'A student with that email already exists.',
        );
      }
    }

    const row = await this.studentRepository.update(id, {
      student_uid: payload.studentId ?? existing.student_uid,
      full_name: payload.name ?? existing.full_name,
      email: payload.email ?? existing.email,
      department: payload.department ?? existing.department,
      batch: payload.batch ?? existing.batch,
      course: payload.course ?? existing.course,
      phone: payload.phone ?? existing.phone,
      profile_photo_url: payload.profilePhotoUrl ?? existing.profile_photo_url,
    });

    await this.auditService.logRequest(request, {
      action: 'STUDENT_UPDATED',
      entityType: 'student',
      entityId: id,
    });

    return toStudentJson(row);
  }

  async remove(id, request) {
    const existing = await this.studentRepository.findById(id);
    if (!existing) {
      throw ApiError.notFound('STUDENT_NOT_FOUND', 'Student not found.');
    }
    await this.studentRepository.remove(id);

    await this.auditService.logRequest(request, {
      action: 'STUDENT_DELETED',
      entityType: 'student',
      entityId: id,
    });
  }
}

module.exports = StudentService;
