class ProfessionalSimultaneityEstimate {
  final double factor;
  final double installedPowerW;
  final double simultaneousPowerW;
  final String basis;

  const ProfessionalSimultaneityEstimate({
    required this.factor,
    required this.installedPowerW,
    required this.simultaneousPowerW,
    required this.basis,
  });
}

class ProfessionalSimultaneityEstimator {
  const ProfessionalSimultaneityEstimator();

  ProfessionalSimultaneityEstimate bySimultaneousQuantity({
    required int totalQuantity,
    required int simultaneousQuantity,
    required double unitPowerW,
  }) {
    if (totalQuantity < 1 ||
        simultaneousQuantity < 1 ||
        simultaneousQuantity > totalQuantity ||
        unitPowerW <= 0) {
      throw ArgumentError('Invalid simultaneity estimation inputs.');
    }
    final installed = totalQuantity * unitPowerW;
    final simultaneous = simultaneousQuantity * unitPowerW;
    return ProfessionalSimultaneityEstimate(
      factor: simultaneousQuantity / totalQuantity,
      installedPowerW: installed,
      simultaneousPowerW: simultaneous,
      basis:
          '$simultaneousQuantity de $totalQuantity unidades informadas como simultâneas.',
    );
  }

  ProfessionalSimultaneityEstimate bySimultaneousDemand({
    required int totalQuantity,
    required double unitPowerW,
    required double simultaneousPowerW,
  }) {
    if (totalQuantity < 1 || unitPowerW <= 0 || simultaneousPowerW <= 0) {
      throw ArgumentError('Invalid simultaneity estimation inputs.');
    }
    final installed = totalQuantity * unitPowerW;
    if (simultaneousPowerW > installed) {
      throw ArgumentError('Simultaneous demand cannot exceed installed power.');
    }
    return ProfessionalSimultaneityEstimate(
      factor: simultaneousPowerW / installed,
      installedPowerW: installed,
      simultaneousPowerW: simultaneousPowerW,
      basis:
          'Demanda simultânea informada de ${simultaneousPowerW.toStringAsFixed(1)} W para ${installed.toStringAsFixed(1)} W instalados.',
    );
  }

  ProfessionalSimultaneityEstimate withoutDiversity({
    required int totalQuantity,
    required double unitPowerW,
  }) {
    if (totalQuantity < 1 || unitPowerW <= 0) {
      throw ArgumentError('Invalid simultaneity estimation inputs.');
    }
    final installed = totalQuantity * unitPowerW;
    return ProfessionalSimultaneityEstimate(
      factor: 1,
      installedPowerW: installed,
      simultaneousPowerW: installed,
      basis: 'Sem diversidade: 100% da carga instalada considerada simultânea.',
    );
  }
}
