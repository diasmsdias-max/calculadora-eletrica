import 'dart:convert';

import 'package:crypto/crypto.dart';

class VisBackupEnvelope {
  static const format = 'vis-electrica-backup';
  static const currentVersion = 1;

  final int version;
  final DateTime createdAt;
  final String appVersion;
  final Map<String, dynamic> payload;
  final String integrity;

  const VisBackupEnvelope._({
    required this.version,
    required this.createdAt,
    required this.appVersion,
    required this.payload,
    required this.integrity,
  });

  factory VisBackupEnvelope.create({
    required DateTime createdAt,
    required String appVersion,
    required Map<String, dynamic> payload,
  }) {
    final normalizedPayload = _normalizeMap(payload);
    return VisBackupEnvelope._(
      version: currentVersion,
      createdAt: createdAt.toUtc(),
      appVersion: appVersion,
      payload: normalizedPayload,
      integrity: _digest(normalizedPayload),
    );
  }

  factory VisBackupEnvelope.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Backup inválido.');
    }
    final json = Map<String, dynamic>.from(decoded);
    if (json['format'] != format || json['version'] != currentVersion) {
      throw const FormatException('Formato ou versão de backup incompatível.');
    }
    final payloadValue = json['payload'];
    if (payloadValue is! Map) {
      throw const FormatException('Payload de backup inválido.');
    }
    final payload = _normalizeMap(Map<String, dynamic>.from(payloadValue));
    final integrity = json['integrity'];
    if (integrity is! String || integrity != _digest(payload)) {
      throw const FormatException('Integridade do backup inválida.');
    }
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final appVersion = json['appVersion'];
    if (createdAt == null || appVersion is! String || appVersion.isEmpty) {
      throw const FormatException('Metadados do backup inválidos.');
    }
    return VisBackupEnvelope._(
      version: currentVersion,
      createdAt: createdAt.toUtc(),
      appVersion: appVersion,
      payload: payload,
      integrity: integrity,
    );
  }

  String encode() => jsonEncode({
        'format': format,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'payload': payload,
        'integrity': integrity,
      });

  static String _digest(Map<String, dynamic> payload) =>
      sha256.convert(utf8.encode(_canonicalJson(payload))).toString();

  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(value)) as Map,
      );

  static String _canonicalJson(Object? value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final keys = map.keys.toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(map[key])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }
}
