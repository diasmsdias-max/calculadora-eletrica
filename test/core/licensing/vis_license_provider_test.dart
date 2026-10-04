import 'dart:convert';

import 'package:calculadora_eletrica/core/licensing/license_state.dart';
import 'package:calculadora_eletrica/core/licensing/vis_credential_verifier.dart';
import 'package:calculadora_eletrica/core/licensing/vis_license_api.dart';
import 'package:calculadora_eletrica/core/licensing/vis_license_provider.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Ed25519 algorithm;
  late KeyPair keyPair;
  late SimplePublicKey publicKey;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    algorithm = Ed25519();
    keyPair = await algorithm.newKeyPair();
    publicKey = await keyPair.extractPublicKey() as SimplePublicKey;
  });

  Future<Map<String, dynamic>> credentialFor({
    required String installationId,
    DateTime? offlineValidUntil,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'contractVersion': 1,
      'credentialFormat': 'VIS-LIC-1',
      'licenseId': 'license-test',
      'installationIdHash': _sha256Hex(installationId),
      'plan': 'professional',
      'permissions': ['professional'],
      'issuedAt': now.toIso8601String(),
      'offlineValidUntil':
          (offlineValidUntil ?? now.add(const Duration(days: 7)))
              .toIso8601String(),
      'commercialValidUntil':
          now.add(const Duration(days: 365)).toIso8601String(),
      'keyId': 'test-key',
    };
    final encoded =
        base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
    final signature = await algorithm.sign(
      utf8.encode(encoded),
      keyPair: keyPair,
    );
    return {
      'format': 'VIS-LIC-1',
      'payload': encoded,
      'signature': base64Url.encode(signature.bytes).replaceAll('=', ''),
      'keyId': 'test-key',
    };
  }

  VisCredentialVerifier verifier() => VisCredentialVerifier(
        expectedKeyId: 'test-key',
        publicKeyBytes: publicKey.bytes,
      );

  test('activation persists signed credential across provider recreation',
      () async {
    const installationId = 'installation-12345678901234567890';
    SharedPreferences.setMockInitialValues({
      'vis_license_installation_id': installationId,
    });
    final credential = await credentialFor(installationId: installationId);
    final provider = VisLicenseProvider(
      api: _FakeLicenseApi({'credential': credential}),
      verifier: verifier(),
    );

    final activated = await provider.activate('VIS-PRO-TEST');
    final reopenedProvider = VisLicenseProvider(
      api: _FakeLicenseApi(const {}),
      verifier: verifier(),
    );

    expect(activated.hasProfessional, isTrue);
    expect((await reopenedProvider.currentState()).hasProfessional, isTrue);
  });

  test('credential cannot be restored onto a different installation', () async {
    final credential = await credentialFor(
      installationId: 'original-installation-1234567890',
    );

    final result = await verifier().verify(
      credential: credential,
      installationId: 'different-installation-123456789',
    );

    expect(result, isNull);
  });

  test('tampered signed payload is rejected', () async {
    const installationId = 'installation-12345678901234567890';
    final credential = await credentialFor(installationId: installationId);
    final payload = credential['payload']! as String;
    credential['payload'] = '${payload.substring(0, payload.length - 1)}A';

    final result = await verifier().verify(
      credential: credential,
      installationId: installationId,
    );

    expect(result, isNull);
  });

  test('expired offline credential requests online validation', () async {
    const installationId = 'installation-12345678901234567890';
    SharedPreferences.setMockInitialValues({
      'vis_license_installation_id': installationId,
      'vis_license_credential': jsonEncode(await credentialFor(
        installationId: installationId,
        offlineValidUntil:
            DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      )),
    });
    final provider = VisLicenseProvider(
      api: _FakeLicenseApi(const {}),
      verifier: verifier(),
    );

    final state = await provider.currentState();

    expect(state.status, LicenseStatus.validationRequired);
    expect(state.hasProfessional, isFalse);
  });
}

class _FakeLicenseApi extends VisLicenseApi {
  final Map<String, dynamic> response;

  _FakeLicenseApi(this.response)
      : super(Uri.parse('https://license.test/api/'));

  @override
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async =>
      response;
}

String _sha256Hex(String value) {
  return hashes.sha256.convert(utf8.encode(value)).toString();
}
