import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'professional_profile.dart';

abstract interface class ProfessionalProfileRepository {
  Future<ProfessionalProfile?> load();
  Future<void> save(ProfessionalProfile profile);
  Future<void> clear();
}

class LocalProfessionalProfileRepository
    implements ProfessionalProfileRepository {
  static const _key = 'professional_profile_v1';

  @override
  Future<ProfessionalProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ProfessionalProfile.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      ).normalized();
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(ProfessionalProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.normalized().toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
