import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_board.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_load.dart';
import 'package:calculadora_eletrica/core/professional/professional_material.dart';
import 'package:calculadora_eletrica/core/professional/professional_memorial.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/professional_protection.dart';
import 'package:calculadora_eletrica/core/professional/professional_sizing.dart';
import 'package:calculadora_eletrica/core/professional/vis_project_package.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1);
  test('VIS Project round trip preserves ids, revisions and relations', () {
    final package = VisProjectPackage(
      project: ProfessionalProject(id:'p', revision:3, name:'Projeto', createdAt:t, updatedAt:t),
      loads:[ProfessionalLoad(id:'l',projectId:'p',revision:2,name:'Motor',quantity:1,powerW:1000,voltageV:220,createdAt:t,updatedAt:t)],
      circuits:[ProfessionalCircuit(id:'c',projectId:'p',revision:4,name:'C1',createdAt:t,updatedAt:t)],
      boards:[ProfessionalBoard(id:'b',projectId:'p',revision:1,name:'QD1',status:ProfessionalBoardStatus.closed,closedAt:t,createdAt:t,updatedAt:t)],
      protections:[ProfessionalProtection(id:'pr',projectId:'p',circuitId:'c',revision:1,name:'Disjuntor',createdAt:t,updatedAt:t)],
      sizing:[ProfessionalSizing(id:'s',projectId:'p',circuitId:'c',revision:2,createdAt:t,updatedAt:t)],
      materials:[ProfessionalMaterial(id:'m',projectId:'p',revision:1,description:'Cabo',createdAt:t,updatedAt:t)],
      memorial:ProfessionalMemorial(id:'mem',projectId:'p',revision:5,title:'Memorial',createdAt:t,updatedAt:t),
      circuitLoadIds:{'c':['l']},
      boardCircuitIds:{'b':['c']},
    );
    final restored = VisProjectPackage.decode(package.encode());
    expect(restored.project.id,'p'); expect(restored.project.revision,3);
    expect(restored.loads.single.id,'l'); expect(restored.loads.single.revision,2);
    expect(restored.circuits.single.id,'c'); expect(restored.boards.single.id,'b');
    expect(restored.boards.single.status,ProfessionalBoardStatus.closed);
    expect(restored.boards.single.closedAt,t);
    expect(restored.protections.single.circuitId,'c'); expect(restored.sizing.single.circuitId,'c');
    expect(restored.materials.single.id,'m'); expect(restored.memorial!.revision,5);
    expect(restored.circuitLoadIds['c'],['l']); expect(restored.boardCircuitIds['b'],['c']);
  });

  test('legacy board contract v1 opens as open',(){
    final board=ProfessionalBoard.fromPortableJson({
      'contractVersion':1,'id':'b','projectId':'p','revision':1,'name':'QD1',
      'description':'','location':'','notes':'','createdAt':t.toIso8601String(),'updatedAt':t.toIso8601String(),
    });
    expect(board.status,ProfessionalBoardStatus.open);expect(board.closedAt,isNull);
  });

  test('VIS Project rejects broken relation', () {
    final package = VisProjectPackage(
      project:ProfessionalProject(id:'p',revision:1,name:'P',createdAt:t,updatedAt:t),
      circuits:[ProfessionalCircuit(id:'c',projectId:'p',revision:1,name:'C',createdAt:t,updatedAt:t)],
      circuitLoadIds:{'c':['missing']},
    );
    expect(package.validate, throwsFormatException);
  });
}
