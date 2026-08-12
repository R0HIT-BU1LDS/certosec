import 'package:certosec/core/constants/app_enums.dart';
import 'package:certosec/providers/verification_provider.dart';
import 'package:certosec/repositories/verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late VerificationProvider provider;

  VerificationProvider buildProvider(FakeVerificationGateway gateway) {
    return VerificationProvider(VerificationRepository(gateway: gateway));
  }

  tearDown(() {
    provider.dispose();
  });

  test('verifyByUid returns a valid verdict for a known UID', () async {
    final gateway = FakeVerificationGateway();
    provider = buildProvider(gateway);

    expect(provider.isLoading, isFalse);
    await provider.verifyByUid('CERT-2026-000001');

    expect(provider.hasResult, isTrue);
    expect(provider.result!.isValid, isTrue);
    expect(provider.result!.status, VerificationStatus.valid);
    expect(provider.result!.studentName, 'Alice Johnson');
    expect(provider.hasError, isFalse);
  });

  test('verifyByUid returns an invalid verdict for an unknown UID', () async {
    final gateway = FakeVerificationGateway();
    provider = buildProvider(gateway);

    await provider.verifyByUid('CERT-2026-099999');

    expect(provider.hasResult, isTrue);
    expect(provider.result!.isValid, isFalse);
    expect(provider.result!.status, VerificationStatus.invalid);
  });

  test('verifyByUid resets the previous result before a new check', () async {
    final gateway = FakeVerificationGateway();
    provider = buildProvider(gateway);

    await provider.verifyByUid('CERT-2026-000001');
    expect(provider.result!.isValid, isTrue);

    await provider.verifyByUid('CERT-2026-099999');
    expect(provider.result!.isValid, isFalse);
    expect(gateway.verifyCalls, 2);
  });

  test('clear resets result and error', () async {
    final gateway = FakeVerificationGateway();
    provider = buildProvider(gateway);
    await provider.verifyByUid('CERT-2026-000001');

    provider.clear();
    expect(provider.hasResult, isFalse);
    expect(provider.hasError, isFalse);
  });

  test('verifyByTxHash returns a valid verdict for a known hash', () async {
    final gateway = FakeVerificationGateway();
    provider = buildProvider(gateway);

    await provider.verifyByTxHash(
      '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1f3b6776c3d0b7f2c2c39d4a11',
    );

    expect(provider.hasResult, isTrue);
    expect(provider.result!.isValid, isTrue);
    expect(provider.result!.status, VerificationStatus.valid);
    expect(provider.result!.transactionHash, startsWith('0x'));
    expect(gateway.verifyHashCalls, 1);
  });

  test('verifyByTxHash returns an invalid verdict for an unknown hash',
      () async {
    final gateway = FakeVerificationGateway();
    provider = buildProvider(gateway);

    await provider.verifyByTxHash(
      '0x1111111111111111111111111111111111111111111111111111111111111111',
    );

    expect(provider.hasResult, isTrue);
    expect(provider.result!.isValid, isFalse);
    expect(provider.result!.status, VerificationStatus.invalid);
  });

  test('verifyByTxHash resets the previous UID result', () async {
    final gateway = FakeVerificationGateway();
    provider = buildProvider(gateway);

    await provider.verifyByUid('CERT-2026-000001');
    expect(provider.result!.isValid, isTrue);

    await provider.verifyByTxHash(
      '0x1111111111111111111111111111111111111111111111111111111111111111',
    );
    expect(provider.result!.isValid, isFalse);
  });
}
