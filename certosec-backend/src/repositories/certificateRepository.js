const { toApiError, escapeLike } = require('../utils/db');

/**
 * CertificateRepository owns `certificates` rows. The certificate UID is the
 * stable public identifier; `id` is the internal UUID.
 */
class CertificateRepository {
  constructor(db) {
    this.db = db;
  }

  async paginate({ page, pageSize, search, status }) {
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = this.db.from('certificates').select('*', { count: 'exact' });
    if (search) {
      const term = escapeLike(search.trim());
      query = query.or(
        `certificate_uid.ilike.%${term}%,student_name.ilike.%${term}%`,
      );
    }
    if (status) {
      query = query.eq('status', status);
    }
    query = query.order('created_at', { ascending: false }).range(from, to);

    const { data, error, count } = await query;
    if (error) throw toApiError(error, 'list certificates');
    return {
      items: data || [],
      total: count ?? 0,
      page,
      pageSize,
    };
  }

  async findByUid(uid) {
    const { data, error } = await this.db
      .from('certificates')
      .select('*')
      .eq('certificate_uid', uid)
      .maybeSingle();
    if (error) throw toApiError(error, 'find certificate by uid');
    return data;
  }

  async findById(id) {
    const { data, error } = await this.db
      .from('certificates')
      .select('*')
      .eq('id', id)
      .maybeSingle();
    if (error) throw toApiError(error, 'find certificate by id');
    return data;
  }

  async findByTransactionHash(txHash) {
    const { data, error } = await this.db
      .from('certificates')
      .select('*')
      .eq('transaction_hash', txHash)
      .maybeSingle();
    if (error) throw toApiError(error, 'find certificate by transaction hash');
    return data;
  }

  /** Largest UID of the current year, used to derive the next sequence number. */
  async latestUidForYear(year) {
    const prefix = `CERT-${year}-`;
    const { data, error } = await this.db
      .from('certificates')
      .select('certificate_uid')
      .like('certificate_uid', `${prefix}%`)
      .order('certificate_uid', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error) throw toApiError(error, 'next certificate uid');
    return data ? data.certificate_uid : null;
  }

  async create(payload) {
    const { data, error } = await this.db
      .from('certificates')
      .insert(payload)
      .select('*')
      .single();
    if (error) throw toApiError(error, 'create certificate');
    return data;
  }

  async update(id, payload) {
    const { data, error } = await this.db
      .from('certificates')
      .update(payload)
      .eq('id', id)
      .select('*')
      .maybeSingle();
    if (error) throw toApiError(error, 'update certificate');
    return data;
  }

  async countAll() {
    const { count, error } = await this.db
      .from('certificates')
      .select('id', { count: 'exact', head: true });
    if (error) throw toApiError(error, 'count certificates');
    return count ?? 0;
  }

  async countByStatus(status) {
    const { count, error } = await this.db
      .from('certificates')
      .select('id', { count: 'exact', head: true })
      .eq('status', status);
    if (error) throw toApiError(error, 'count certificates by status');
    return count ?? 0;
  }

  /** Certificates issued between start (inclusive) and end (exclusive). */
  async countIssuedBetween(startIso, endIso) {
    const { count, error } = await this.db
      .from('certificates')
      .select('id', { count: 'exact', head: true })
      .gte('created_at', startIso)
      .lt('created_at', endIso);
    if (error) throw toApiError(error, 'count certificates issued today');
    return count ?? 0;
  }
}

module.exports = CertificateRepository;
