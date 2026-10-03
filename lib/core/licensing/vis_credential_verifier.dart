import 'dart:convert';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';

class VisLicenseCredential {
  final String licenseId;
  final String plan;
  final Set<String> permissions;
  final DateTime issuedAt;
  final DateTime offlineValidUntil;
  final DateTime commercialValidUntil;

  const VisLicenseCredential({
    required this.licenseId,
    required this.plan,
    required this.permissions,
    required this.issuedAt,
    required this.offlineValidUntil,
    required this.commercialValidUntil,
  });

  bool get isOfflineValid =>
      DateTime.now().toUtc().isBefore(offlineValidUntil) &&
      DateTime.now().toUtc().isBefore(commercialValidUntil);
}

class VisCredentialVerifier {
  final String expectedKeyId;
  final List<int> publicKeyBytes;

  const VisCredentialVerifier({
    required this.expectedKeyId,
    required this.publicKeyBytes,
  });

  Future<VisLicenseCredential?> verify({
    required Map<String, dynamic> credential,
    required String installationId,
  }) async {
    if (credential['format'] != 'VIS-LIC-1' ||
        credential['keyId'] != expectedKeyId) {
      return null;
    }
    final payloadEncoded = credential['payload'];
    final signatureEncoded = credential['signature'];
    if (payloadEncoded is! String || signatureEncoded is! String) return null;

    final algorithm = Ed25519();
    final signature = Signature(
      base64Url.decode(base64Url.normalize(signatureEncoded)),
      publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
    );
    final valid = await algorithm.verify(
      utf8.encode(payloadEncoded),
      signature: signature,
    );
    if (!valid) return null;

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(payloadEncoded))),
    );
    if (payload is! Map<String, dynamic> ||
        payload['contractVersion'] != 1 ||
        payload['credentialFormat'] != 'VIS-LIC-1' ||
        payload['keyId'] != expectedKeyId) {
      return null;
    }

    final localInstallationHash =
        hashes.sha256.convert(utf8.encode(installationId)).toString();
    if (payload['installationIdHash'] != localInstallationHash) return null;

    final permissions = payload['permissions'];
    if (permissions is! List) return null;
    try {
      return VisLicenseCredential(
        licenseId: payload['licenseId'] as String,
        plan: payload['plan'] as String,
        permissions: permissions.whereType<String>().toSet(),
        issuedAt: DateTime.parse(payload['issuedAt'] as String).toUtc(),
        offlineValidUntil:
            DateTime.parse(payload['offlineValidUntil'] as String).toUtc(),
        commercialValidUntil:
            DateTime.parse(payload['commercialValidUntil'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}
