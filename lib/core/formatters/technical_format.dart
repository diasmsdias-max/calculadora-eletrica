abstract final class TechnicalFormat {
  static String number(num value, {int decimals = 2}) {
    if (!value.toDouble().isFinite) return 'não determinado';
    final fixed = value.toDouble().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final negative = parts[0].startsWith('-');
    final digits = negative ? parts[0].substring(1) : parts[0];
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final integer = negative ? '-$grouped' : grouped;
    return decimals == 0 ? integer : '$integer,${parts[1]}';
  }

  static String unit(num value, String unit, {int decimals = 2}) =>
      '${number(value, decimals: decimals)} $unit';
}
