const { toApiError } = require('../utils/db');

/**
 * AuditRepository owns `audit_logs` rows. Every important action is written
 * here (LOGIN, CERTIFICATE_ISSUED, CERTIFICATE_VERIFIED, ...).
 */
class AuditRepository {
  constructor(db) {
    this.db = db;
  }

  async create({ userId, action, entityType, entityId, ipAddress, userAgent, metadata }) {
    const { error } = await this.db.from('audit_logs').insert({
      user_id: userId || null,
      action,
      entity_type: entityType || null,
      entity_id: entityId ? String(entityId) : null,
      ip_address: ipAddress || null,
      user_agent: userAgent || null,
      metadata: metadata || null,
    });
    if (error) throw toApiError(error, 'write audit log');
  }

  async paginate({ page, pageSize }) {
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    const { data, error, count } = await this.db
      .from('audit_logs')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);
    if (error) throw toApiError(error, 'list audit logs');
    return { items: data || [], total: count ?? 0, page, pageSize };
  }
}

module.exports = AuditRepository;
