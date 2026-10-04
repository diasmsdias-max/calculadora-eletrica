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
   sizing:[ProfessionalSizing(id:'s',projectId:'p',circuitId:'c',revision:1,designCurrentA:18.5,conductorSectionMm2:4,conductorAmpacityA:28,createdAt:t,updatedAt:t)],
   protections:[ProfessionalProtection(id:'pr',projectId:'p',circuitId:'c',revision:1,name:'DJ',role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:20,createdAt:t,updatedAt:t)]);
  expect(result.scope,startsWith('Quadro QD1 consolidado no VIS ELECTRICA:'));
  expect(result.scope,contains('1 carga(s), 1 circuito(s) e 1 quadro(s)'));
  expect(result.scope,contains('1 fechado(s)'));
  expect(result.criteria,contains('Dimensionamentos registrados: 1/1'));
  expect(result.criteria,contains('C1: dimensionado; 1 proteção(ões); Ib=18.5 A; In=20 A; Iz=28 A; condutor=4 mm².'));
 });
 test('uses project context when snapshot contains multiple boards',(){
  final t=DateTime.utc(2026,10,3);
  final result=const ProfessionalMemorialConsolidator().build(
   boards:[
    ProfessionalBoard(id:'b1',projectId:'p',revision:1,name:'QD1',createdAt:t,updatedAt:t),
    ProfessionalBoard(id:'b2',projectId:'p',revision:1,name:'QD2',createdAt:t,updatedAt:t),
   ],
   circuits:const[],loads:const[],sizing:const[],protections:const[]);
  expect(result.scope,startsWith('Projeto elétrico consolidado no VIS ELECTRICA:'));
  expect(result.scope,isNot(contains('Quadro QD1 consolidado')));
 });

 test('omits electrical values that were not registered',(){
  final t=DateTime.utc(2026,10,3);
  final result=const ProfessionalMemorialConsolidator().build(
   boards:const[],circuits:[ProfessionalCircuit(id:'c',projectId:'p',revision:1,name:'C2',createdAt:t,updatedAt:t)],
   loads:const[],sizing:const[],protections:const[]);
  expect(result.criteria,contains('C2: sem dimensionamento; 0 proteção(ões).'));
  expect(result.criteria, isNot(contains('Ib=')));
  expect(result.criteria, isNot(contains('In=')));
  expect(result.criteria, isNot(contains('Iz=')));
  expect(result.criteria, isNot(contains('condutor=')));
 });
}