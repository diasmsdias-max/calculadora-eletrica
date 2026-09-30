import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_project.dart';

abstract interface class ProjectRepository {
  Future<List<LocalProject>> getAll();
  Future<void> save(LocalProject project);
  Future<void> delete(String id);
}

class PreferencesProjectRepository implements ProjectRepository {
  static const _key = 'local_projects_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<LocalProject>> getAll() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final projects = decoded
        .map((e) => LocalProject.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<void> save(LocalProject project) async {
    final projects = await getAll();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.add(project);
    }
    await (await _prefs).setString(
      _key,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  }

  @override
  Future<void> delete(String id) async {
    final projects = await getAll();
    projects.removeWhere((p) => p.id == id);
    await (await _prefs).setString(
      _key,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  }
}
