import '../../models/dashboard_stats.dart';

/// DashboardGateway is the contract for the dashboard data backend.
///
/// Like [AuthGateway], screens depend on this interface, never on the HTTP
/// implementation directly, so tests can substitute an in-memory fake.
abstract interface class DashboardGateway {
  Future<DashboardStats> fetchStats();
}
