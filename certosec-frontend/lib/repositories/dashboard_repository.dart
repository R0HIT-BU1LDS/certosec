import '../models/dashboard_stats.dart';
import '../services/api/dashboard_gateway.dart';

/// DashboardRepository orchestrates dashboard data reads.
///
/// Today it forwards to the gateway; it exists as the single place where any
/// future caching or aggregation of dashboard statistics would live.
class DashboardRepository {
  DashboardRepository({required DashboardGateway gateway}) : _gateway = gateway;

  final DashboardGateway _gateway;

  Future<DashboardStats> fetchStats() => _gateway.fetchStats();
}
