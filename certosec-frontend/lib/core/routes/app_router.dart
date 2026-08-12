import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/certificates/certificate_details_screen.dart';
import '../../screens/certificates/certificates_screen.dart';
import '../../screens/certificates/issue_certificate_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/home/home_shell.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/students/add_edit_student_screen.dart';
import '../../screens/students/student_details_screen.dart';
import '../../screens/students/students_screen.dart';
import '../../screens/verification/verification_result_screen.dart';
import '../../screens/verification/verification_screen.dart';
import '../constants/app_enums.dart';
import 'route_names.dart';

/// AppRouter owns the single GoRouter instance for the application.
///
/// It is created once in the composition root (main.dart) and injected into
/// the widget tree, so navigation state survives widget rebuilds. Route
/// protection lives in the `redirect` callback, which re-evaluates every time
/// `AuthProvider` notifies a change — this is how login moves the user to the
/// dashboard and logout kicks them back to the login screen without any screen
/// having to call `go` explicitly.
///
/// Public routes (login, verification) are registered at the root. The
/// authenticated app lives under a `StatefulShellRoute.indexedStack` so the
/// bottom navigation (Dashboard / Students / Certificates / Profile) is
/// shared, and each tab preserves its scroll position and provider state while
/// switching.
class AppRouter {
  AppRouter({required AuthProvider authProvider}) : _auth = authProvider {
    _router = GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: _auth,
      redirect: _redirect,
      routes: _routes,
    );
  }

  final AuthProvider _auth;
  late final GoRouter _router;

  GoRouter get router => _router;

  /// Route table. Public routes registered directly; the authenticated app is
  /// a four-branch stateful shell:
  /// - Dashboard tab: `/dashboard`
  /// - Students tab: `/students`, `/students/add`, `/students/:id`,
  ///   `/students/:id/edit`
  /// - Certificates tab: `/certificates`, `/certificates/issue`,
  ///   `/certificates/:uid`
  /// - Profile tab: `/profile`, `/settings`
  static final List<RouteBase> _routes = [
    GoRoute(path: RouteNames.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(path: RouteNames.login, builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: RouteNames.verification,
      builder: (_, _) => const VerificationScreen(),
    ),
    GoRoute(
      path: RouteNames.verificationResult,
      builder: (_, state) => VerificationResultScreen(
        uid: state.uri.queryParameters['uid'] ?? '',
        txHash: state.uri.queryParameters['txHash'] ?? '',
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.dashboard,
              builder: (_, _) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.students,
              builder: (_, _) => const StudentsScreen(),
            ),
            GoRoute(
              path: RouteNames.studentAdd,
              builder: (_, _) => const AddEditStudentScreen(),
            ),
            GoRoute(
              path: RouteNames.studentDetails,
              builder: (_, state) =>
                  StudentDetailsScreen(studentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: RouteNames.studentEdit,
              builder: (_, state) =>
                  AddEditStudentScreen(studentId: state.pathParameters['id']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.certificates,
              builder: (_, _) => const CertificatesScreen(),
            ),
            GoRoute(
              path: RouteNames.issueCertificate,
              builder: (_, _) => const IssueCertificateScreen(),
            ),
            GoRoute(
              path: RouteNames.certificateDetails,
              builder: (_, state) => CertificateDetailsScreen(
                uid: state.pathParameters['uid']!,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.profile,
              builder: (_, _) => const ProfileScreen(),
            ),
            GoRoute(
              path: RouteNames.settings,
              builder: (_, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ];

  String? _redirect(BuildContext context, GoRouterState state) {
    final status = _auth.status;
    final location = state.matchedLocation;
    final atSplash = location == RouteNames.splash;
    final onPublicRoute = RouteNames.publicRoutes.contains(location);

    // While the session is still being checked, only the splash may render.
    if (status == AuthStatus.unknown) {
      return atSplash ? null : RouteNames.splash;
    }

    // The splash decides where a known session goes next.
    if (atSplash) {
      return status == AuthStatus.authenticated
          ? RouteNames.dashboard
          : RouteNames.login;
    }

    // Signed-in users never land on the login screen.
    if (status == AuthStatus.authenticated && location == RouteNames.login) {
      return RouteNames.dashboard;
    }

    // Signed-out users are barred from private routes.
    if (status == AuthStatus.unauthenticated && !onPublicRoute) {
      return RouteNames.login;
    }

    return null;
  }
}
