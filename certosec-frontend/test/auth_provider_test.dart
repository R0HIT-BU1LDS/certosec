import 'package:certosec/core/constants/app_enums.dart';
import 'package:certosec/providers/auth_provider.dart';
import 'package:certosec/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late InMemorySessionStorage storage;
  late FakeAuthGateway gateway;
  late AuthProvider provider;

  setUp(() {
    storage = InMemorySessionStorage();
    gateway = FakeAuthGateway();
    provider = AuthProvider(AuthRepository(gateway: gateway, storage: storage));
  });

  group('AuthProvider.login', () {
    test('persists tokens and flips to authenticated', () async {
      final ok = await provider.login(
        email: FakeAuthGateway.adminUser.email,
        password: 'password123',
      );

      expect(ok, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user?.role, UserRole.admin);
      expect(provider.errorMessage, isNull);
      expect(await storage.readToken(), 'access-token');
      expect(await storage.readRefreshToken(), 'refresh-token');
    });

    test(
      'on failure exposes the server message and stays signed out',
      () async {
        final ok = await provider.login(
          email: FakeAuthGateway.adminUser.email,
          password: 'wrong-password',
        );

        expect(ok, isFalse);
        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.errorMessage, 'Invalid email or password.');
        expect(await storage.readToken(), isNull);
      },
    );

    test('ignores a second call while a login is in flight', () async {
      final first = provider.login(
        email: FakeAuthGateway.adminUser.email,
        password: 'password123',
      );
      final second = await provider.login(
        email: FakeAuthGateway.adminUser.email,
        password: 'password123',
      );
      await first;

      expect(second, isFalse);
      expect(gateway.loginCalls, 1);
    });
  });

  group('AuthProvider.checkSession', () {
    test('no token means signed out without a network call', () async {
      await provider.checkSession();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(gateway.currentUserCalls, 0);
    });

    test('valid token fetches the profile and signs in', () async {
      await storage.writeToken('access-token');
      await provider.checkSession();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user?.email, FakeAuthGateway.adminUser.email);
      expect(gateway.currentUserCalls, 1);
    });
  });

  group('AuthProvider.logout', () {
    test('clears every secret and returns to signed out', () async {
      await storage.writeToken('access-token');
      await storage.writeRefreshToken('refresh-token');
      await provider.checkSession();
      expect(provider.status, AuthStatus.authenticated);

      await provider.logout();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(await storage.readToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    });
  });

  group('AuthProvider.forgotPassword', () {
    test('returns true when the server accepts the request', () async {
      final ok = await provider.forgotPassword(FakeAuthGateway.adminUser.email);

      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
    });
  });
}
