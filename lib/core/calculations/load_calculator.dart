class LoadResult {
  final double installedKw;
  final double demandKw;
  final double apparentKva;
  final double dailyKwh;
  final double monthlyKwh;

  const LoadResult({
    required this.installedKw,
    required this.demandKw,
    required this.apparentKva,
    required this.dailyKwh,
    required this.monthlyKwh,
  });
}

abstract final class LoadCalculator {
  static LoadResult calculate({
    required double unitPowerKw,
    required int quantity,
    required double powerFactor,
    required double simultaneity,
    required double hoursPerDay,
    required int daysPerMonth,
  }) {
    if (!unitPowerKw.isFinite || unitPowerKw < 0) {
      throw ArgumentError('Potência unitária inválida.');
    }
    if (quantity < 0) throw ArgumentError('Quantidade inválida.');
    if (!powerFactor.isFinite || powerFactor <= 0 || powerFactor > 1) {
      throw ArgumentError('Fator de potência deve estar entre 0 e 1.');
    }
    if (!simultaneity.isFinite || simultaneity < 0 || simultaneity > 1) {
      throw ArgumentError('Simultaneidade deve estar entre 0 e 1.');
    }
    if (!hoursPerDay.isFinite || hoursPerDay < 0 || hoursPerDay > 24) {
      throw ArgumentError('Horas/dia inválidas.');
    }
    if (daysPerMonth < 0 || daysPerMonth > 31) {
      throw ArgumentError('Dias/mês inválidos.');
    }

    final installed = unitPowerKw * quantity;
    final demand = installed * simultaneity;

    return LoadResult(
      installedKw: installed,
      demandKw: demand,
      apparentKva: demand / powerFactor,
      dailyKwh: installed * hoursPerDay,
      monthlyKwh: installed * hoursPerDay * daysPerMonth,
    );
  }
}
