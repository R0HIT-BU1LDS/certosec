const { toApiError, escapeLike } = require('../utils/db');

/**
 * StudentRepository owns `students` rows. All SQL access for students lives
 * here; controllers and services never issue raw queries.
 */
class StudentRepository {
  constructor(db) {
    this.db = db;
  }

  async paginate({ page, pageSize, search, department }) {
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = this.db.from('students').select('*', { count: 'exact' });
    if (search) {
      const term = escapeLike(search.trim());
      query = query.or(`full_name.ilike.%${term}%,student_uid.ilike.%${term}%`);
    }
    if (department) {
      query = query.eq('department', department);
    }
    query = query.order('created_at', { ascending: false }).range(from, to);

    const { data, error, count } = await query;
    if (error) throw toApiError(error, 'list students');
    return {
      items: data || [],
      total: count ?? 0,
      page,
      pageSize,
    };
  }

  async findById(id) {
    const { data, error } = await this.db
      .from('students')
      .select('*')
      .eq('id', id)
      .maybeSingle();
    if (error) throw toApiError(error, 'find student');
    return data;
  }

  async findByStudentUid(studentUid) {
    const { data, error } = await this.db
      .from('students')
      .select('*')
      .eq('student_uid', studentUid)
      .maybeSingle();
    if (error) throw toApiError(error, 'find student by uid');
    return data;
  }

  async findByEmail(email) {
    const { data, error } = await this.db
      .from('students')
      .select('*')
      .eq('email', email.toLowerCase())
      .maybeSingle();
    if (error) throw toApiError(error, 'find student by email');
    return data;
  }

  async create(payload) {
    const { data, error } = await this.db
      .from('students')
      .insert(payload)
      .select('*')
      .single();
    if (error) throw toApiError(error, 'create student');
    return data;
  }

  async update(id, payload) {
    const { data, error } = await this.db
      .from('students')
      .update(payload)
      .eq('id', id)
      .select('*')
      .maybeSingle();
    if (error) throw toApiError(error, 'update student');
    return data;
  }

  async remove(id) {
    const { error } = await this.db.from('students').delete().eq('id', id);
    if (error) throw toApiError(error, 'delete student');
  }

  async countAll() {
    const { count, error } = await this.db
      .from('students')
      .select('id', { count: 'exact', head: true });
    if (error) throw toApiError(error, 'count students');
    return count ?? 0;
  }
}

module.exports = StudentRepository;
