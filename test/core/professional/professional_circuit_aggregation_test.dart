import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit_aggregation.dart';
import 'package:calculadora_eletrica/core/professional/professional_load.dart';

void main() {
  const aggregator=ProfessionalCircuitAggregator();
  final now=DateTime.utc(2026,1,1);

  ProfessionalCircuit circuit({double? voltage=220,int? phases=1}) =>
    ProfessionalCircuit(id:'c1',projectId:'p1',revision:1,name:'C1',
      voltageV:voltage,phases:phases,createdAt:now,updatedAt:now);

  ProfessionalLoad load({
    String id='l1',double power=2200,double voltage=220,double? pf=1,int quantity=1,
  }) => ProfessionalLoad(id:id,projectId:'p1',revision:1,name:id,
    powerW:power,voltageV:voltage,powerFactor:pf,quantity:quantity,
    createdAt:now,updatedAt:now);

  test('reports insufficient data when circuit has no loads',(){
    final result=aggregator.calculate(circuit:circuit(),loads:const []);
    expect(result.currentStatus,CircuitCalculationStatus.insufficientData);
    expect(result.designCurrentA,isNull);
    expect(result.totalPowerW,0);
  });

  test('reports insufficient data when a load has no power factor',(){
    final result=aggregator.calculate(circuit:circuit(),loads:[load(pf:null)]);
    expect(result.currentStatus,CircuitCalculationStatus.insufficientData);
    expect(result.designCurrentA,isNull);
  });

  test('rejects load voltage incompatible with circuit voltage',(){
    final result=aggregator.calculate(
      circuit:circuit(voltage:220),loads:[load(voltage:127)]);
    expect(result.currentStatus,CircuitCalculationStatus.incompatibleData);
    expect(result.designCurrentA,isNull);
  });

  test('calculates single phase current from apparent power',(){
    final result=aggregator.calculate(
      circuit:circuit(voltage:220,phases:1),
      loads:[load(power:2200,voltage:220,pf:1)]);
    expect(result.currentStatus,CircuitCalculationStatus.calculated);
    expect(result.totalPowerW,2200);
    expect(result.designCurrentA,closeTo(10,0.0001));
  });

  test('calculates three phase current using square root of three',(){
    final result=aggregator.calculate(
      circuit:circuit(voltage:380,phases:3),
      loads:[load(power:3800,voltage:380,pf:1)]);
    expect(result.currentStatus,CircuitCalculationStatus.calculated);
    expect(result.designCurrentA,closeTo(3800/(math.sqrt(3)*380),0.0001));
  });

  test('sums quantities and apparent power using each load power factor',(){
    final result=aggregator.calculate(
      circuit:circuit(voltage:220,phases:1),
      loads:[
        load(id:'a',power:880,voltage:220,pf:0.8,quantity:2),
        load(id:'b',power:550,voltage:220,pf:0.5),
      ]);
    expect(result.linkedLoadCount,2);
    expect(result.totalQuantity,3);
    expect(result.totalPowerW,2310);
    expect(result.designCurrentA,closeTo(15,0.0001));
  });
}
