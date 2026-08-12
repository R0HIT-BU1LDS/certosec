const logger = require('../utils/logger');

/**
 * AuditService writes audit rows for important actions. A failed audit write
 * is logged but never allowed to fail the operation that triggered it.
 */
class AuditService {
  constructor({ auditRepository }) {
    this.auditRepository = auditRepository;
  }

  async log({ userId, action, entityType, entityId, ipAddress, userAgent, metadata }) {
    try {
      await this.auditRepository.create({
        userId,
        action,
        entityType,
        entityId,
        ipAddress,
        userAgent,
        metadata,
      });
    } catch (err) {
      logger.error(`Audit log write failed for ${action}`, {
        entityId,
        message: err.message,
      });
    }
  }

  /** Logs using values derived from the Express request. */
  logRequest(req, { action, entityType, entityId, metadata, userId }) {
    return this.log({
      userId: userId ?? req?.user?.id ?? null,
      action,
      entityType,
      entityId,
      ipAddress: req?.ip || null,
      userAgent: (req && typeof req.get === 'function' ? req.get('user-agent') : null) || null,
      metadata,
    });
  }
}

module.exports = AuditService;
