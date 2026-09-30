import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'project_record.dart';

abstract interface class ProjectRecordRepository {
  Future<List<ProjectRecord>> getByProject(String projectId);
  Future<void> save(ProjectRecord record);
  Future<void> delete(String id);
  Future<void> deleteByProject(String projectId);
}

class PreferencesProjectRecordRepository implements ProjectRecordRepository {
  static const _key = 'project_records_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<ProjectRecord>> _all() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ProjectRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _write(List<ProjectRecord> records) async {
    await (await _prefs).setString(
      _key,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  @override
  Future<List<ProjectRecord>> getByProject(String projectId) async {
    final records = (await _all()).where((r) => r.projectId == projectId).toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  Future<void> save(ProjectRecord record) async {
    final records = await _all();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await _write(records);
  }

  @override
  Future<void> delete(String id) async {
    final records = await _all();
    records.removeWhere((r) => r.id == id);
    await _write(records);
  }

  @override
  Future<void> deleteByProject(String projectId) async {
    final records = await _all();
    records.removeWhere((r) => r.projectId == projectId);
    await _write(records);
  }
}
