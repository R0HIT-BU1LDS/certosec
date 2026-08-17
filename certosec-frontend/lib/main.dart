import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/certificates_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/students_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/verification_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/certificate_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/student_repository.dart';
import 'repositories/verification_repository.dart';
import 'services/api/api_client.dart';
import 'services/api/auth_api.dart';
import 'services/api/auth_gateway.dart';
import 'services/api/certificate_api.dart';
import 'services/api/certificate_gateway.dart';
import 'services/api/dashboard_api.dart';
import 'services/api/dashboard_gateway.dart';
import 'services/api/student_api.dart';
import 'services/api/student_gateway.dart';
import 'services/api/verification_api.dart';
import 'services/api/verification_gateway.dart';
import 'services/storage/secure_storage_service.dart';
import 'services/storage/settings_storage_service.dart';

/// Composition root — the single place where the object graph is constructed.
///
/// Services and providers are created once here and injected downward. The
/// GoRouter is also built here (wired to AuthProvider) so that navigation
/// state and redirect decisions live for the entire app lifetime.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = SecureStorageService();
  final settingsStorage = SettingsStorageService(secureStorage);

  final apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    timeout: AppConfig.apiTimeout,
    accessTokenProvider: () => secureStorage.readToken(),
  );
  final AuthGateway authGateway = AuthApi(apiClient);
  final authRepository = AuthRepository(
    gateway: authGateway,
    storage: secureStorage,
  );

  final DashboardGateway dashboardGateway = DashboardApi(apiClient);
  final dashboardRepository = DashboardRepository(gateway: dashboardGateway);

  final StudentGateway studentGateway = StudentApi(apiClient);
  final studentRepository = StudentRepository(gateway: studentGateway);

  final CertificateGateway certificateGateway = CertificateApi(apiClient);
  final certificateRepository = CertificateRepository(
    gateway: certificateGateway,
  );

  final VerificationGateway verificationGateway = VerificationApi(apiClient);
  final verificationRepository = VerificationRepository(
    gateway: verificationGateway,
  );

  final authProvider = AuthProvider(authRepository);
  final dashboardProvider = DashboardProvider(dashboardRepository);
  final studentsProvider = StudentsProvider(studentRepository);
  final certificatesProvider = CertificatesProvider(certificateRepository);
  final verificationProvider = VerificationProvider(verificationRepository);
  final themeProvider = ThemeProvider(settingsStorage);
  final router = AppRouter(authProvider: authProvider).router;

  runApp(
    CertoSecApp(
      router: router,
      authProvider: authProvider,
      dashboardProvider: dashboardProvider,
      studentsProvider: studentsProvider,
      certificatesProvider: certificatesProvider,
      verificationProvider: verificationProvider,
      themeProvider: themeProvider,
    ),
  );
}

class CertoSecApp extends StatelessWidget {
  const CertoSecApp({
    super.key,
    required this.router,
    required this.authProvider,
    required this.dashboardProvider,
    required this.studentsProvider,
    required this.certificatesProvider,
    required this.verificationProvider,
    required this.themeProvider,
  });

  final GoRouter router;
  final AuthProvider authProvider;
  final DashboardProvider dashboardProvider;
  final StudentsProvider studentsProvider;
  final CertificatesProvider certificatesProvider;
  final VerificationProvider verificationProvider;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DashboardProvider>.value(
          value: dashboardProvider,
        ),
        ChangeNotifierProvider<StudentsProvider>.value(value: studentsProvider),
        ChangeNotifierProvider<CertificatesProvider>.value(
          value: certificatesProvider,
        ),
        ChangeNotifierProvider<VerificationProvider>.value(
          value: verificationProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.themeMode,
            routerConfig: router,
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
