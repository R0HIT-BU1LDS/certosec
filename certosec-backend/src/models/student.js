/**
 * Student serialization. The frontend `Student` model expects
 * `{ id, studentId, name, email, department, batch, course, phone,
 *   profilePhotoUrl, createdAt, updatedAt }`.
 */
function toStudentJson(row) {
  return {
    id: row.id,
    studentId: row.student_uid,
    name: row.full_name,
    email: row.email || null,
    department: row.department,
    batch: row.batch,
    course: row.course,
    phone: row.phone || null,
    profilePhotoUrl: row.profile_photo_url || null,
    createdAt: row.created_at || null,
    updatedAt: row.updated_at || null,
  };
}

module.exports = { toStudentJson };
