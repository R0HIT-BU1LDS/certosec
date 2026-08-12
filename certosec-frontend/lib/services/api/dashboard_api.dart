import '../../models/dashboard_stats.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'dashboard_gateway.dart';

/// DashboardApi is the HTTP implementation of [DashboardGateway].
///
///   GET /dashboard/stats  (authenticated)
class DashboardApi implements DashboardGateway {
  DashboardApi(this._client);

  final ApiClient _client;

  @override
  Future<DashboardStats> fetchStats() async {
    final response = await _client.get(ApiEndpoints.dashboardStats);
    return DashboardStats.fromJson(response.data! as Map<String, dynamic>);
  }
}
