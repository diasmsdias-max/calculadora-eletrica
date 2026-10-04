import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_board_material_consolidator.dart';
import 'package:calculadora_eletrica/core/professional/professional_protection.dart';

void main(){
  test('consolidates equal protections only from board circuits',(){
    final t=DateTime.utc(2026,10,3);
    ProfessionalProtection p(String id,String circuit)=>ProfessionalProtection(
      id:id,projectId:'p',circuitId:circuit,revision:1,name:'Disjuntor',
      deviceType:'Disjuntor termomagnético',role:ProfessionalProtectionRole.overcurrent,
      ratedCurrentA:20,poles:2,tripCurve:'C',createdAt:t,updatedAt:t);
    final items=const ProfessionalBoardMaterialConsolidator().build(
      projectId:'p',boardId:'q1',circuitIds:['c1','c2'],
      protections:[p('a','c1'),p('b','c2'),p('x','c3')],generatedAt:t);
    expect(items,hasLength(1));expect(items.single.quantity,2);
    expect(items.single.source,'VIS:q1');expect(items.single.notes,contains('20 A'));
  });
}