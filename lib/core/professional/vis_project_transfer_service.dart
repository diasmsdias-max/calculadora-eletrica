import 'package:sqflite/sqflite.dart';

import 'vis_project_package.dart';

class VisProjectTransferService {
  final Database database;
  const VisProjectTransferService(this.database);

  Future<String> exportProject(String projectId) async {
    final projects = await database.query('professional_projects', where:'id = ?', whereArgs:[projectId], limit:1);
    if (projects.isEmpty) throw ArgumentError('Professional project not found.');
    final loads = await _byProject('professional_loads', projectId);
    final circuits = await _byProject('professional_circuits', projectId);
    final boards = await _byProject('professional_boards', projectId);
    final protections = await _byProject('professional_protections', projectId);
    final sizing = await _byProject('professional_sizing', projectId);
    final materials = await _byProject('professional_materials', projectId);
    final memorials = await _byProject('professional_memorials', projectId);
    final circuitIds = circuits.map((e)=>e['id'] as String).toList();
    final boardIds = boards.map((e)=>e['id'] as String).toList();

    final circuitLoads = <String,List<String>>{};
    for(final id in circuitIds){
      final rows=await database.query('professional_circuit_loads',columns:['load_id'],where:'circuit_id = ?',whereArgs:[id]);
      if(rows.isNotEmpty)circuitLoads[id]=rows.map((e)=>e['load_id'] as String).toList();
    }
    final boardCircuits = <String,List<String>>{};
    for(final id in boardIds){
      final rows=await database.query('professional_board_circuits',columns:['circuit_id'],where:'board_id = ?',whereArgs:[id]);
      if(rows.isNotEmpty)boardCircuits[id]=rows.map((e)=>e['circuit_id'] as String).toList();
    }

    final package=VisProjectPackage.fromJson({
      'format':VisProjectPackage.format,'contractVersion':VisProjectPackage.contractVersion,
      'project':_portable(projects.single),
      'loads':loads.map(_portable).toList(),'circuits':circuits.map(_portable).toList(),
      'boards':boards.map(_portable).toList(),'protections':protections.map(_portable).toList(),
      'sizing':sizing.map(_portable).toList(),'materials':materials.map(_portable).toList(),
      if(memorials.isNotEmpty)'memorial':_portable(memorials.single),
      'relations':{'circuitLoads':circuitLoads,'boardCircuits':boardCircuits},
    });
    return package.encode();
  }

  Future<void> importProject(String source) async {
    final package=VisProjectPackage.decode(source);
    await database.transaction((txn) async {
      await txn.delete('professional_projects',where:'id = ?',whereArgs:[package.project.id]);
      await txn.insert('professional_projects',_db(package.project.toPortableJson()));
      for (final e in package.loads) {
        await txn.insert('professional_loads', _db(e.toPortableJson()));
      }
      for (final e in package.circuits) {
        await txn.insert('professional_circuits', _db(e.toPortableJson()));
      }
      for (final e in package.boards) {
        await txn.insert('professional_boards', _db(e.toPortableJson()));
      }
      for (final e in package.protections) {
        await txn.insert('professional_protections', _db(e.toPortableJson()));
      }
      for (final e in package.sizing) {
        await txn.insert('professional_sizing', _db(e.toPortableJson()));
      }
      for (final e in package.materials) {
        await txn.insert('professional_materials', _db(e.toPortableJson()));
      }
      if(package.memorial!=null) await txn.insert('professional_memorials',_db(package.memorial!.toPortableJson()));
      for (final entry in package.circuitLoadIds.entries) {
        for (final loadId in entry.value) {
        await txn.insert('professional_circuit_loads', {'circuit_id':entry.key,'load_id':loadId});
        }
      }
      for (final entry in package.boardCircuitIds.entries) {
        for (final circuitId in entry.value) {
        await txn.insert('professional_board_circuits', {'board_id':entry.key,'circuit_id':circuitId});
        }
      }
    });
  }

  Future<List<Map<String,Object?>>> _byProject(String table,String id)=>
    database.query(table,where:'project_id = ?',whereArgs:[id]);

  static Map<String,Object?> _portable(Map<String,Object?> row) {
    final r=Map<String,Object?>.from(row);
    final map=<String,String>{
      'contract_version':'contractVersion','project_id':'projectId','circuit_id':'circuitId',
      'power_w':'powerW','voltage_v':'voltageV','power_factor':'powerFactor',
      'simultaneity_factor':'simultaneityFactor','simultaneity_source':'simultaneitySource',
      'simultaneity_basis':'simultaneityBasis',
      'rated_current_a':'ratedCurrentA','recommended_current_a':'recommendedCurrentA',
      'validation_status':'validationStatus','validation_criterion':'validationCriterion',
      'device_type':'deviceType','protection_role':'role','trip_curve':'tripCurve',
      'breaking_capacity_ka':'breakingCapacityKa','design_current_a':'designCurrentA',
      'conductor_section_mm2':'conductorSectionMm2','conductor_ampacity_a':'conductorAmpacityA','voltage_drop_percent':'voltageDropPercent',
      'protection_current_a':'protectionCurrentA','closed_at':'closedAt','created_at':'createdAt','updated_at':'updatedAt'
    };
    for(final e in map.entries){if(r.containsKey(e.key)){r[e.value]=r.remove(e.key);}}
    return r;
  }

  static Map<String,Object?> _db(Map<String,Object?> portable) {
    final r=Map<String,Object?>.from(portable);
    final contractVersion=r.remove('contractVersion');
    final map=<String,String>{
      'projectId':'project_id','circuitId':'circuit_id','powerW':'power_w','voltageV':'voltage_v',
      'powerFactor':'power_factor','simultaneityFactor':'simultaneity_factor',
      'simultaneitySource':'simultaneity_source','simultaneityBasis':'simultaneity_basis',
      'ratedCurrentA':'rated_current_a',
      'recommendedCurrentA':'recommended_current_a','validationStatus':'validation_status',
      'validationCriterion':'validation_criterion','deviceType':'device_type','role':'protection_role',
      'tripCurve':'trip_curve','breakingCapacityKa':'breaking_capacity_ka','designCurrentA':'design_current_a',
      'conductorSectionMm2':'conductor_section_mm2','conductorAmpacityA':'conductor_ampacity_a','voltageDropPercent':'voltage_drop_percent',
      'protectionCurrentA':'protection_current_a','closedAt':'closed_at','createdAt':'created_at','updatedAt':'updated_at'
    };
    for(final e in map.entries){if(r.containsKey(e.key)){r[e.value]=r.remove(e.key);}}
    r['contract_version']=contractVersion ?? 1;
    return r;
  }
}
