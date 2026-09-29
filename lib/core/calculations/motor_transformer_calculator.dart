import 'motor_calculator.dart';
import 'power_calculator.dart';
import 'transformer_calculator.dart';

class MotorTransformerResult {
  final MotorResult motor;
  final TransformerResult transformer;
  final double motorTransformerPercent;
  final double startingKvaEstimate;
  final double startingTransformerPercent;

  const MotorTransformerResult({
    required this.motor,
    required this.transformer,
    required this.motorTransformerPercent,
    required this.startingKvaEstimate,
    required this.startingTransformerPercent,
  });
}

abstract final class MotorTransformerCalculator {
  static MotorTransformerResult calculate({
    required double transformerKva,
    required double motorRatedPower,
    required MotorPowerUnit motorUnit,
    required AcSystem system,
    required double voltageV,
    required double powerFactor,
    required double efficiency,
    MotorStartingMethod startingMethod = MotorStartingMethod.direct,
    double? startingMultiplier,
  }) {
    final motor = MotorCalculator.calculate(
      ratedPower: motorRatedPower,
      unit: motorUnit,
      system: system,
      voltageV: voltageV,
      powerFactor: powerFactor,
      efficiency: efficiency,
      startingMethod: startingMethod,
      startingMultiplier: startingMultiplier,
    );

    final transformer = TransformerCalculator.calculate(
      ratedKva: transformerKva,
      system: system,
      voltageV: voltageV,
      loadPowerFactor: powerFactor,
      loadKva: motor.apparentPowerKva,
    );

    final startKva = motor.apparentPowerKva *
        (motor.estimatedStartingCurrentA / motor.nominalCurrentA);

    return MotorTransformerResult(
      motor: motor,
      transformer: transformer,
      motorTransformerPercent: motor.apparentPowerKva / transformerKva * 100,
      startingKvaEstimate: startKva,
      startingTransformerPercent: startKva / transformerKva * 100,
    );
  }
}
