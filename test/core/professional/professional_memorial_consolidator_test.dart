import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_board.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_load.dart';
import 'package:calculadora_eletrica/core/professional/professional_memorial_consolidator.dart';
import 'package:calculadora_eletrica/core/professional/professional_protection.dart';
import 'package:calculadora_eletrica/core/professional/professional_sizing.dart';

void main(){
 test('builds memorial snapshot only from registered project data',(){
  final t=DateTime.utc(2026,10,3);
  final result=const ProfessionalMemorialConsolidator().build(
   boards:[ProfessionalBoard(id:'b',projectId:'p',revision:1,name:'QD1',status:ProfessionalBoardStatus.closed,closedAt:t,createdAt:t,updatedAt:t)],
   circuits:[ProfessionalCircuit(id:'c',projectId:'p',revision:1,name:'C1',createdAt:t,updatedAt:t)],
   loads:[ProfessionalLoad(id:'l',projectId:'p',revision:1,name:'Motor',quantity:1,powerW:1000,voltageV:220,createdAt:t,updatedAt:t)],
   sizing:[ProfessionalSizing(id:'s',projectId:'p',circuitId:'c',revision:1,createdAt:t,updatedAt:t)],
   protections:[ProfessionalProtection(id:'pr',projectId:'p',circuitId:'c',revision:1,name:'DJ',createdAt:t,updatedAt:t)]);
  expect(result.scope,contains('1 carga(s), 1 circuito(s) e 1 quadro(s)'));
  expect(result.scope,contains('1 fechado(s)'));
  expect(result.criteria,contains('Dimensionamentos registrados: 1/1'));
  expect(result.criteria,contains('C1: dimensionado; 1 proteção(ões).'));
 });
}