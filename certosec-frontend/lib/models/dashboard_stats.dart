import '../core/utils/model_utils.dart';

/// DashboardStats is the aggregate counters shown on the admin home screen.
class DashboardStats {
  const DashboardStats({
    required this.totalStudents,
    required this.totalCertificates,
    required this.issuedToday,
    required this.verifiedCertificates,
    required this.pendingCertificates,
  });

  final int totalStudents;
  final int totalCertificates;
  final int issuedToday;
  final int verifiedCertificates;
  final int pendingCertificates;

  const DashboardStats.empty()
    : totalStudents = 0,
      totalCertificates = 0,
      issuedToday = 0,
      verifiedCertificates = 0,
      pendingCertificates = 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: ModelUtils.pickInt(json, [
        'totalStudents',
        'total_students',
        'students',
      ]),
      totalCertificates: ModelUtils.pickInt(json, [
        'totalCertificates',
        'total_certificates',
        'certificates',
      ]),
      issuedToday: ModelUtils.pickInt(json, [
        'certificatesIssuedToday',
        'issuedToday',
        'issued_today',
      ]),
      verifiedCertificates: ModelUtils.pickInt(json, [
        'verifiedCertificates',
        'verified_certificates',
        'verified',
      ]),
      pendingCertificates: ModelUtils.pickInt(json, [
        'pendingCertificates',
        'pending_certificates',
        'pending',
      ]),
    );
  }
}
