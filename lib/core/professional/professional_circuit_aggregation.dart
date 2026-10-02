import 'dart:math' as math;

import 'professional_circuit.dart';
import 'professional_load.dart';

enum CircuitCalculationStatus {
  calculated,
  insufficientData,
  incompatibleData,
}

class ProfessionalCircuitAggregation {
  final double totalPowerW;
  final int linkedLoadCount;
  final int totalQuantity;
  final double? designCurrentA;
  final CircuitCalculationStatus currentStatus;
  final String currentMessage;

  const ProfessionalCircuitAggregation({
    required this.totalPowerW,
    required this.linkedLoadCount,
    required this.totalQuantity,
    required this.designCurrentA,
    required this.currentStatus,
    required this.currentMessage,
  });
}

class ProfessionalCircuitAggregator {
  const ProfessionalCircuitAggregator();

  ProfessionalCircuitAggregation calculate({
    required ProfessionalCircuit circuit,
    required Iterable<ProfessionalLoad> loads,
  }) {
    final list=loads.toList(growable:false);
    final totalPower=list.fold<double>(0,(sum,load)=>sum+load.totalPowerW);
    final quantity=list.fold<int>(0,(sum,load)=>sum+load.quantity);

    if(list.isEmpty) {
      return const ProfessionalCircuitAggregation(
        totalPowerW:0,linkedLoadCount:0,totalQuantity:0,designCurrentA:null,
        currentStatus:CircuitCalculationStatus.insufficientData,
        currentMessage:'Vincule ao menos uma carga ao circuito.',
      );
    }
    final voltage=circuit.voltageV;
    final phases=circuit.phases;
    if(voltage==null||voltage<=0||phases==null) {
      return ProfessionalCircuitAggregation(
        totalPowerW:totalPower,linkedLoadCount:list.length,totalQuantity:quantity,
        designCurrentA:null,currentStatus:CircuitCalculationStatus.insufficientData,
        currentMessage:'Informe a tensão e o número de fases do circuito.',
      );
    }
    if(phases!=1&&phases!=3) {
      return ProfessionalCircuitAggregation(
        totalPowerW:totalPower,linkedLoadCount:list.length,totalQuantity:quantity,
        designCurrentA:null,currentStatus:CircuitCalculationStatus.insufficientData,
        currentMessage:'O cálculo automático de corrente requer circuito monofásico ou trifásico.',
      );
    }
    if(list.any((load)=>load.voltageV<=0||load.powerFactor==null||
        load.powerFactor!<=0||load.powerFactor!>1)) {
      return ProfessionalCircuitAggregation(
        totalPowerW:totalPower,linkedLoadCount:list.length,totalQuantity:quantity,
        designCurrentA:null,currentStatus:CircuitCalculationStatus.insufficientData,
        currentMessage:'Informe tensão e fator de potência válido em todas as cargas.',
      );
    }
    final incompatible=list.any((load)=>(load.voltageV-voltage).abs()>0.01);
    if(incompatible) {
      return ProfessionalCircuitAggregation(
        totalPowerW:totalPower,linkedLoadCount:list.length,totalQuantity:quantity,
        designCurrentA:null,currentStatus:CircuitCalculationStatus.incompatibleData,
        currentMessage:'Há carga com tensão diferente da tensão informada para o circuito.',
      );
    }

    final apparentPowerVa=list.fold<double>(0,(sum,load)=>
      sum+(load.totalPowerW/load.powerFactor!));
    final divisor=phases==3?math.sqrt(3)*voltage:voltage;
    return ProfessionalCircuitAggregation(
      totalPowerW:totalPower,linkedLoadCount:list.length,totalQuantity:quantity,
      designCurrentA:apparentPowerVa/divisor,
      currentStatus:CircuitCalculationStatus.calculated,
      currentMessage:'Corrente calculada com os dados informados nas cargas e no circuito.',
    );
  }
}
