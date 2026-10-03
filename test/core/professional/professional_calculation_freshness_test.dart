import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_calculation_freshness.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_load.dart';
import 'package:calculadora_eletrica/core/professional/professional_sizing.dart';

void main() {
  final base=DateTime.utc(2026,10,3,12);
  ProfessionalCircuit circuit(DateTime updated)=>ProfessionalCircuit(
    id:'c1',projectId:'p1',revision:1,name:'C1',createdAt:base,updatedAt:updated);
  ProfessionalLoad load(DateTime updated)=>ProfessionalLoad(
    id:'l1',projectId:'p1',revision:1,name:'Carga',createdAt:base,updatedAt:updated);
  ProfessionalSizing sizing(DateTime updated)=>ProfessionalSizing(
    id:'s1',projectId:'p1',circuitId:'c1',revision:1,createdAt:base,updatedAt:updated);

  test('marks sizing for review when circuit changed afterwards',(){
    expect(ProfessionalCalculationFreshness.sizingNeedsReview(
      sizing:sizing(base.add(const Duration(hours:1))),
      circuit:circuit(base.add(const Duration(hours:2))),linkedLoads:[load(base)]),isTrue);
  });

  test('marks sizing for review when linked load changed afterwards',(){
    expect(ProfessionalCalculationFreshness.sizingNeedsReview(
      sizing:sizing(base.add(const Duration(hours:1))),circuit:circuit(base),
      linkedLoads:[load(base.add(const Duration(hours:2)))]),isTrue);
  });

  test('keeps sizing current when dependencies are not newer',(){
    expect(ProfessionalCalculationFreshness.sizingNeedsReview(
      sizing:sizing(base.add(const Duration(hours:2))),circuit:circuit(base),
      linkedLoads:[load(base.add(const Duration(hours:1)))]),isFalse);
  });
}
