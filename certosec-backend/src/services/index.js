/**
 * Dependency container: builds the real (production) service graph once and
 * exposes it to controllers. Tests build their own instances with fakes.
 */
const env = require('../config/env');
const { supabase, supabaseAnon } = require('../config/supabase');

const ProfileRepository = require('../repositories/profileRepository');
const StudentRepository = require('../repositories/studentRepository');
const CertificateRepository = require('../repositories/certificateRepository');
const AuditRepository = require('../repositories/auditRepository');

const AuditService = require('./auditService');
const AuthService = require('./authService');
const StudentService = require('./studentService');
const StorageService = require('./storageService');
const CertificateService = require('./certificateService');
const VerificationService = require('./verificationService');
const DashboardService = require('./dashboardService');

const blockchainService = require('../blockchain/blockchainService');

const profileRepository = new ProfileRepository(supabase);
const studentRepository = new StudentRepository(supabase);
const certificateRepository = new CertificateRepository(supabase);
const auditRepository = new AuditRepository(supabase);

const auditService = new AuditService({ auditRepository });
const authService = new AuthService({
  anonAuth: supabaseAnon,
  profileRepository,
  auditService,
  config: env,
});
const storageService = new StorageService({ supabase, config: env });
const studentService = new StudentService({ studentRepository, auditService });
const certificateService = new CertificateService({
  certificateRepository,
  studentRepository,
  storageService,
  blockchainService,
  auditService,
  config: env,
});
const verificationService = new VerificationService({
  certificateRepository,
  blockchainService,
  auditService,
  config: env,
});
const dashboardService = new DashboardService({
  studentRepository,
  certificateRepository,
});

module.exports = {
  authService,
  studentService,
  certificateService,
  verificationService,
  dashboardService,
  auditService,
  // exposed for tests / future routes
  repositories: { profileRepository, studentRepository, certificateRepository, auditRepository },
};
