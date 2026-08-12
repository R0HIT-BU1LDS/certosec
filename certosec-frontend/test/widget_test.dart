import 'package:certosec/core/constants/app_enums.dart';
import 'package:certosec/core/routes/app_router.dart';
import 'package:certosec/main.dart';
import 'package:certosec/providers/auth_provider.dart';
import 'package:certosec/providers/certificates_provider.dart';
import 'package:certosec/providers/dashboard_provider.dart';
import 'package:certosec/providers/students_provider.dart';
import 'package:certosec/providers/theme_provider.dart';
import 'package:certosec/providers/verification_provider.dart';
import 'package:certosec/repositories/auth_repository.dart';
import 'package:certosec/repositories/certificate_repository.dart';
import 'package:certosec/repositories/dashboard_repository.dart';
import 'package:certosec/repositories/student_repository.dart';
import 'package:certosec/repositories/verification_repository.dart';
import 'package:certosec/screens/certificates/certificate_details_screen.dart';
import 'package:certosec/screens/certificates/certificates_screen.dart';
import 'package:certosec/screens/dashboard/dashboard_screen.dart';
import 'package:certosec/screens/login/login_screen.dart';
import 'package:certosec/screens/profile/profile_screen.dart';
import 'package:certosec/screens/settings/settings_screen.dart';
import 'package:certosec/screens/splash/splash_screen.dart';
import 'package:certosec/screens/students/add_edit_student_screen.dart';
import 'package:certosec/screens/students/student_details_screen.dart';
import 'package:certosec/screens/students/students_screen.dart';
import 'package:certosec/screens/verification/verification_result_screen.dart';
import 'package:certosec/screens/verification/verification_screen.dart';
import 'package:certosec/services/storage/session_storage.dart';
import 'package:certosec/services/storage/settings_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/fakes.dart';

/// In-memory implementation of [SettingsStorage] that always defaults to the
/// system theme preference.
class _InMemorySettingsStorage implements SettingsStorage {
  @override
  Future<ThemePreference> readThemePreference() async => ThemePreference.system;

  @override
  Future<void> writeThemePreference(ThemePreference preference) async {}
}

Future<CertoSecApp> buildApp({
  required SessionStorage sessionStorage,
  FakeAuthGateway? authGateway,
  FakeDashboardGateway? dashboardGateway,
  FakeStudentGateway? studentGateway,
  FakeCertificateGateway? certificateGateway,
  FakeVerificationGateway? verificationGateway,
}) async {
  final authRepository = AuthRepository(
    gateway: authGateway ?? FakeAuthGateway(),
    storage: sessionStorage,
  );
  final dashboardRepository = DashboardRepository(
    gateway: dashboardGateway ?? FakeDashboardGateway(),
  );
  final studentRepository = StudentRepository(
    gateway: studentGateway ?? FakeStudentGateway(),
  );
  final certificateRepository = CertificateRepository(
    gateway: certificateGateway ?? FakeCertificateGateway(),
  );
  final verificationRepository = VerificationRepository(
    gateway: verificationGateway ?? FakeVerificationGateway(),
  );
  final authProvider = AuthProvider(authRepository);
  final dashboardProvider = DashboardProvider(dashboardRepository);
  final studentsProvider = StudentsProvider(studentRepository);
  final certificatesProvider = CertificatesProvider(certificateRepository);
  final verificationProvider = VerificationProvider(verificationRepository);
  final themeProvider = ThemeProvider(_InMemorySettingsStorage());
  final router = AppRouter(authProvider: authProvider).router;
  return CertoSecApp(
    router: router,
    authProvider: authProvider,
    dashboardProvider: dashboardProvider,
    studentsProvider: studentsProvider,
    certificatesProvider: certificatesProvider,
    verificationProvider: verificationProvider,
    themeProvider: themeProvider,
  );
}

/// Logs in through the UI (default fake credentials) and settles on the
/// dashboard. The dashboard and student fakes are injected so screens render
/// live data instead of error states.
Future<void> signIn(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    FakeAuthGateway.adminUser.email,
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

Future<void> goToStudentsTab(WidgetTester tester) async {
  await _tapTab(tester, 'Students');
}

Future<void> goToCertificatesTab(WidgetTester tester) async {
  await _tapTab(tester, 'Certificates');
}

Future<void> goToProfileTab(WidgetTester tester) async {
  await _tapTab(tester, 'Profile');
}

/// Taps the destination labelled [label] inside the bottom [NavigationBar].
/// Tapping the bar itself would hit its geometric center, which can fall on
/// the boundary between two destinations, so the label text is targeted.
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

/// Enlarges the test viewport so long forms (add/edit student) render every
/// field and the submit button without scrolling.
void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('app boots to splash and redirects signed-out users to login', (
    tester,
  ) async {
    final app = await buildApp(sessionStorage: InMemorySessionStorage());
    await tester.pumpWidget(app);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('admin signs in, reaches dashboard, and can log out', (
    tester,
  ) async {
    final storage = InMemorySessionStorage();
    final app = await buildApp(sessionStorage: storage);
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await signIn(tester);

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(await storage.readToken(), 'access-token');

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
    expect(await storage.readToken(), isNull);
  });

  testWidgets('invalid credentials show an inline error', (tester) async {
    final app = await buildApp(sessionStorage: InMemorySessionStorage());
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      FakeAuthGateway.adminUser.email,
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('validation rejects malformed input without calling the API', (
    tester,
  ) async {
    final gateway = FakeAuthGateway();
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      authGateway: gateway,
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(gateway.loginCalls, 0);
  });

  testWidgets('dashboard renders live statistics after login', (tester) async {
    final dashboardGateway = FakeDashboardGateway();
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      dashboardGateway: dashboardGateway,
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);

    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('Total Certificates'), findsOneWidget);
    expect(find.text('342'), findsOneWidget);
    expect(dashboardGateway.fetchCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('students tab lists the seeded directory', (tester) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: defaultStudents()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToStudentsTab(tester);

    expect(find.byType(StudentsScreen), findsOneWidget);
    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(find.text('Bob Smith'), findsOneWidget);
    expect(find.text('Carol White'), findsOneWidget);
  });

  testWidgets('search filters students by name', (tester) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: defaultStudents()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToStudentsTab(tester);

    await tester.enterText(find.byType(TextField).first, 'alice');
    // Advance past the search debounce.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(find.text('Bob Smith'), findsNothing);
  });

  testWidgets('department filter narrows the list', (tester) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: defaultStudents()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToStudentsTab(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Computer Science'));
    await tester.pumpAndSettle();

    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(find.text('Bob Smith'), findsNothing);
    expect(find.text('Carol White'), findsNothing);
  });

  testWidgets('tapping a student opens their details', (tester) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: defaultStudents()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToStudentsTab(tester);

    await tester.tap(find.text('Alice Johnson'));
    await tester.pumpAndSettle();

    expect(find.byType(StudentDetailsScreen), findsOneWidget);
    expect(find.text('alice@university.edu'), findsOneWidget);
    expect(find.text('BSc Computer Science'), findsOneWidget);
    expect(find.text('CS-2024-001'), findsWidgets);
  });

  testWidgets('add student form validates then creates and returns to list', (
    tester,
  ) async {
    useTallViewport(tester);
    final studentGateway = FakeStudentGateway(seed: defaultStudents());
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: studentGateway,
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);

    // Add via the dashboard quick action.
    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();
    expect(find.byType(AddEditStudentScreen), findsOneWidget);

    // Empty submit shows validation errors.
    await tester.tap(find.byKey(const Key('student-form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Student ID is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'PHY-2025-099');
    await tester.enterText(find.byType(TextFormField).at(1), 'Dana Green');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'dana.green@university.edu',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '2025');
    await tester.enterText(find.byType(TextFormField).at(4), 'BSc Physics');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Physics').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('student-form-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(StudentsScreen), findsOneWidget);
    expect(find.text('Dana Green'), findsOneWidget);

    // Let the snackbar timer elapse before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('edit student updates the record', (tester) async {
    useTallViewport(tester);
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: defaultStudents()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToStudentsTab(tester);

    await tester.tap(find.text('Alice Johnson'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit student'));
    await tester.pumpAndSettle();

    expect(find.byType(AddEditStudentScreen), findsOneWidget);
    expect(find.text('Alice Johnson'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Alice J. Johnson',
    );
    await tester.tap(find.byKey(const Key('student-form-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(StudentsScreen), findsOneWidget);
    expect(find.text('Alice J. Johnson'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('delete student confirms then removes from the list', (
    tester,
  ) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: defaultStudents()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToStudentsTab(tester);

    await tester.tap(find.text('Bob Smith'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete student'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Bob Smith?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(StudentsScreen), findsOneWidget);
    expect(find.text('Bob Smith'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('empty directory shows the add-student empty state', (
    tester,
  ) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: const []),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToStudentsTab(tester);

    expect(find.text('No students yet'), findsOneWidget);
    expect(find.text('Add student'), findsOneWidget);
  });

  testWidgets('certificates tab lists the seeded ledger', (tester) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      certificateGateway: FakeCertificateGateway(seed: defaultCertificates()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToCertificatesTab(tester);

    expect(find.byType(CertificatesScreen), findsOneWidget);
    expect(find.text('BSc Computer Science'), findsOneWidget);
    expect(find.text('BEng Electrical'), findsOneWidget);
    expect(find.textContaining('CERT-2026-000001'), findsOneWidget);
  });

  testWidgets('tapping a certificate opens its details with a QR code', (
    tester,
  ) async {
    useTallViewport(tester);
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      certificateGateway: FakeCertificateGateway(seed: defaultCertificates()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToCertificatesTab(tester);

    await tester.tap(find.text('BSc Computer Science'));
    await tester.pumpAndSettle();

    expect(find.byType(CertificateDetailsScreen), findsOneWidget);
    expect(find.text('Shareable QR code'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Blockchain proof'), findsOneWidget);
    expect(find.text('polygon-mumbai'), findsOneWidget);
  });

  testWidgets('copying the verification link shows a confirmation', (
    tester,
  ) async {
    useTallViewport(tester);
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      certificateGateway: FakeCertificateGateway(seed: defaultCertificates()),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToCertificatesTab(tester);

    await tester.tap(find.text('BSc Computer Science'));
    await tester.pumpAndSettle();

    // The clipboard is a platform channel that never responds in tests;
    // satisfy it so the confirmation snackbar is shown.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );

    await tester.tap(find.text('Copy verification link'));
    await tester.pumpAndSettle();

    expect(find.text('Verification link copied.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('issuing a certificate navigates to its details', (tester) async {
    useTallViewport(tester);
    final certificateGateway = FakeCertificateGateway();
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      studentGateway: FakeStudentGateway(seed: defaultStudents()),
      certificateGateway: certificateGateway,
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);

    await tester.tap(find.text('Issue Certificate'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice Johnson').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Bachelor of Science in Computer Science',
    );

    await tester.tap(find.byKey(const Key('issue-certificate-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(CertificateDetailsScreen), findsOneWidget);
    expect(find.text('Shareable QR code'), findsOneWidget);
    expect(certificateGateway.issueCalls, 1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('signed-out users can verify a certificate by UID', (
    tester,
  ) async {
    final verificationGateway = FakeVerificationGateway();
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      verificationGateway: verificationGateway,
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Verify a certificate'));
    await tester.pumpAndSettle();
    expect(find.byType(VerificationScreen), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      'CERT-2026-000001',
    );
    await tester.tap(find.byKey(const Key('verify-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(VerificationResultScreen), findsOneWidget);
    expect(find.text('Certificate verified'), findsOneWidget);
    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(verificationGateway.verifyCalls, 1);
  });

  testWidgets('verifying an unknown UID shows the invalid verdict', (
    tester,
  ) async {
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      verificationGateway: FakeVerificationGateway(),
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify a certificate'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'CERT-2026-099999');
    await tester.tap(find.byKey(const Key('verify-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Certificate not found'), findsOneWidget);
  });

  testWidgets('verifying by transaction hash shows the valid verdict', (
    tester,
  ) async {
    final verificationGateway = FakeVerificationGateway();
    final app = await buildApp(
      sessionStorage: InMemorySessionStorage(),
      verificationGateway: verificationGateway,
    );
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Verify a certificate'));
    await tester.pumpAndSettle();
    expect(find.byType(VerificationScreen), findsOneWidget);

    await tester.tap(find.text('Transaction Hash'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1f3b6776c3d0b7f2c2c39d4a11',
    );
    await tester.tap(find.byKey(const Key('verify-hash-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(VerificationResultScreen), findsOneWidget);
    expect(find.text('Certificate verified'), findsOneWidget);
    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(verificationGateway.verifyHashCalls, 1);
  });

  testWidgets('profile tab shows the signed-in operator', (tester) async {
    final app = await buildApp(sessionStorage: InMemorySessionStorage());
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToProfileTab(tester);

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Jane Admin'), findsOneWidget);
    expect(find.text('admin@university.edu'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('settings screen switches the app to dark mode', (tester) async {
    final app = await buildApp(sessionStorage: InMemorySessionStorage());
    await tester.pumpWidget(app);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    await signIn(tester);
    await goToProfileTab(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });
}
