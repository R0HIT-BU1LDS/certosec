/**
 * DashboardService aggregates the counters rendered on the admin home screen.
 * The response matches the Flutter DashboardStats model:
 *   { totalStudents, totalCertificates, certificatesIssuedToday, issuedToday,
 *     verifiedCertificates, pendingCertificates }
 */
class DashboardService {
  constructor({ studentRepository, certificateRepository }) {
    this.studentRepository = studentRepository;
    this.certificateRepository = certificateRepository;
  }

  async stats() {
    const now = new Date();
    const startOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);

    const [totalStudents, totalCertificates, verifiedCertificates, pendingCertificates, issuedToday] =
      await Promise.all([
        this.studentRepository.countAll(),
        this.certificateRepository.countAll(),
        this.certificateRepository.countByStatus('verified'),
        this.certificateRepository.countByStatus('pending'),
        this.certificateRepository.countIssuedBetween(
          startOfDay.toISOString(),
          endOfDay.toISOString(),
        ),
      ]);

    return {
      totalStudents,
      totalCertificates,
      certificatesIssuedToday: issuedToday,
      issuedToday,
      verifiedCertificates,
      pendingCertificates,
    };
  }
}

module.exports = DashboardService;
