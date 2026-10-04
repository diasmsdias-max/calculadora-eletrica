import 'dart:convert';

import 'professional_board.dart';
import 'professional_circuit.dart';
import 'professional_load.dart';
import 'professional_material.dart';
import 'professional_memorial.dart';
import 'professional_project.dart';
import 'professional_protection.dart';
import 'professional_sizing.dart';

class VisProjectPackage {
  static const format = 'VISPROJECT';
  static const contractVersion = 1;

  final ProfessionalProject project;
  final List<ProfessionalLoad> loads;
  final List<ProfessionalCircuit> circuits;
  final List<ProfessionalBoard> boards;
  final List<ProfessionalProtection> protections;
  final List<ProfessionalSizing> sizing;
  final List<ProfessionalMaterial> materials;
  final ProfessionalMemorial? memorial;
  final Map<String, List<String>> circuitLoadIds;
  final Map<String, List<String>> boardCircuitIds;

  const VisProjectPackage({
    required this.project,
    this.loads = const [],
    this.circuits = const [],
    this.boards = const [],
    this.protections = const [],
    this.sizing = const [],
    this.materials = const [],
    this.memorial,
    this.circuitLoadIds = const {},
    this.boardCircuitIds = const {},
  });

  Map<String, Object?> toJson() => {
    'format': format,
    'contractVersion': contractVersion,
    'project': project.toPortableJson(),
    'loads': loads.map((e) => e.toPortableJson()).toList(growable: false),
    'circuits': circuits.map((e) => e.toPortableJson()).toList(growable: false),
    'boards': boards.map((e) => e.toPortableJson()).toList(growable: false),
    'protections': protections.map((e) => e.toPortableJson()).toList(growable: false),
    'sizing': sizing.map((e) => e.toPortableJson()).toList(growable: false),
    'materials': materials.map((e) => e.toPortableJson()).toList(growable: false),
    if (memorial != null) 'memorial': memorial!.toPortableJson(),
    'relations': {
      'circuitLoads': circuitLoadIds,
      'boardCircuits': boardCircuitIds,
    },
  };

  String encode() => jsonEncode(toJson());

  factory VisProjectPackage.decode(String source) {
    final raw = jsonDecode(source);
    if (raw is! Map) throw const FormatException('Invalid VIS Project package.');
    return VisProjectPackage.fromJson(Map<String, Object?>.from(raw));
  }

  factory VisProjectPackage.fromJson(Map<String, Object?> json) {
    if (json['format'] != format) throw const FormatException('Invalid VIS Project format.');
    if (json['contractVersion'] != contractVersion) {
      throw const FormatException('Unsupported VIS Project contract.');
    }
    final projectRaw = _map(json['project'], 'project');
    final project = ProfessionalProject.fromPortableJson(projectRaw);
    final loads = _list(json['loads'], 'loads', ProfessionalLoad.fromPortableJson);
    final circuits = _list(json['circuits'], 'circuits', ProfessionalCircuit.fromPortableJson);
    final boards = _list(json['boards'], 'boards', ProfessionalBoard.fromPortableJson);
    final protections = _list(json['protections'], 'protections', ProfessionalProtection.fromPortableJson);
    final sizing = _list(json['sizing'], 'sizing', ProfessionalSizing.fromPortableJson);
    final materials = _list(json['materials'], 'materials', ProfessionalMaterial.fromPortableJson);
    final memorialRaw = json['memorial'];
    final memorial = memorialRaw == null ? null : ProfessionalMemorial.fromPortableJson(_map(memorialRaw, 'memorial'));
    final relations = _map(json['relations'], 'relations');
    final package = VisProjectPackage(
      project: project,
      loads: loads,
      circuits: circuits,
      boards: boards,
      protections: protections,
      sizing: sizing,
      materials: materials,
      memorial: memorial,
      circuitLoadIds: _relations(relations['circuitLoads'], 'circuitLoads'),
      boardCircuitIds: _relations(relations['boardCircuits'], 'boardCircuits'),
    );
    package.validate();
    return package;
  }

  void validate() {
    final projectId = project.id;
    if (projectId.isEmpty) throw const FormatException('Invalid project id.');
    final loadIds = _unique(loads.map((e) => e.id), 'load');
    final circuitIds = _unique(circuits.map((e) => e.id), 'circuit');
    final boardIds = _unique(boards.map((e) => e.id), 'board');
    _unique(protections.map((e) => e.id), 'protection');
    _unique(sizing.map((e) => e.id), 'sizing');
    _unique(materials.map((e) => e.id), 'material');

    for (final e in loads) { _sameProject(e.projectId, projectId, 'load'); }
    for (final e in circuits) { _sameProject(e.projectId, projectId, 'circuit'); }
    for (final e in boards) { _sameProject(e.projectId, projectId, 'board'); }
    for (final e in protections) {
      _sameProject(e.projectId, projectId, 'protection');
      if (!circuitIds.contains(e.circuitId)) throw const FormatException('Protection references unknown circuit.');
    }
    final sizedCircuits = <String>{};
    for (final e in sizing) {
      _sameProject(e.projectId, projectId, 'sizing');
      if (!circuitIds.contains(e.circuitId)) throw const FormatException('Sizing references unknown circuit.');
      if (!sizedCircuits.add(e.circuitId)) {
        throw const FormatException('Circuit has more than one sizing record.');
      }
    }
    for (final e in materials) { _sameProject(e.projectId, projectId, 'material'); }
    if (memorial != null) {
      if (memorial!.id.isEmpty) throw const FormatException('Invalid memorial id.');
      _sameProject(memorial!.projectId, projectId, 'memorial');
    }

    for (final entry in circuitLoadIds.entries) {
      if (!circuitIds.contains(entry.key)) throw const FormatException('Relation references unknown circuit.');
      if (entry.value.toSet().length != entry.value.length) {
        throw const FormatException('Duplicate circuit-load relation.');
      }
      for (final id in entry.value) {
        if (!loadIds.contains(id)) throw const FormatException('Relation references unknown load.');
      }
    }
    final assignedCircuits = <String>{};
    for (final entry in boardCircuitIds.entries) {
      if (!boardIds.contains(entry.key)) throw const FormatException('Relation references unknown board.');
      if (entry.value.toSet().length != entry.value.length) {
        throw const FormatException('Duplicate board-circuit relation.');
      }
      for (final id in entry.value) {
        if (!circuitIds.contains(id)) throw const FormatException('Relation references unknown circuit.');
        if (!assignedCircuits.add(id)) throw const FormatException('Circuit assigned to more than one board.');
      }
    }
  }

  static Map<String, Object?> _map(Object? value, String name) {
    if (value is! Map) throw FormatException('Invalid $name in VIS Project.');
    return Map<String, Object?>.from(value);
  }

  static List<T> _list<T>(Object? value, String name, T Function(Map<String, Object?>) parse) {
    if (value is! List) throw FormatException('Invalid $name in VIS Project.');
    return value.map((e) => parse(_map(e, name))).toList(growable: false);
  }

  static Map<String, List<String>> _relations(Object? value, String name) {
    if (value is! Map) throw FormatException('Invalid $name relations.');
    return value.map((key, raw) {
      if (key is! String || raw is! List || raw.any((e) => e is! String)) {
        throw FormatException('Invalid $name relations.');
      }
      return MapEntry(key, raw.cast<String>().toList(growable: false));
    });
  }

  static Set<String> _unique(Iterable<String> ids, String type) {
    final result = <String>{};
    for (final id in ids) {
      if (id.isEmpty || !result.add(id)) throw FormatException('Invalid or duplicate $type id.');
    }
    return result;
  }

  static void _sameProject(String actual, String expected, String type) {
    if (actual != expected) throw FormatException('$type belongs to another project.');
  }
}
