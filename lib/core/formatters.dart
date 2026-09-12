/// Utilidades de formato numérico.
///
/// Escritas a mano para no depender de `intl` y mantener una sola dependencia
/// externa en el MVP.
library;

String _groupThousands(String digits) {
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `S/ 425,000`
String formatMoney(double value, {int decimals = 0}) {
  final bool negative = value < 0;
  final String fixed = value.abs().toStringAsFixed(decimals);
  final List<String> parts = fixed.split('.');
  final String intPart = _groupThousands(parts[0]);
  final String decPart = parts.length > 1 ? '.${parts[1]}' : '';
  return '${negative ? '-' : ''}S/ $intPart$decPart';
}

/// `S/ 425.0 K`
String formatMoneyCompact(double value) {
  final double abs = value.abs();
  final String sign = value < 0 ? '-' : '';
  if (abs >= 1000000) return '${sign}S/ ${(abs / 1000000).toStringAsFixed(2)} M';
  if (abs >= 1000) return '${sign}S/ ${(abs / 1000).toStringAsFixed(1)} K';
  return '${sign}S/ ${abs.toStringAsFixed(0)}';
}

/// `320 h`
String formatHours(double value) => '${_groupThousands(value.round().toString())} h';

/// `86%`
String formatPercent(double fraction, {int decimals = 0}) =>
    '${(fraction * 100).toStringAsFixed(decimals)}%';

/// `0.92`
String formatIndex(double value) => value.toStringAsFixed(2);

/// `+3 periodos` / `-1 periodo`
String formatPeriods(double value) {
  final String sign = value > 0 ? '+' : '';
  final String unit = value.abs() == 1 ? 'periodo' : 'periodos';
  return '$sign${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} $unit';
}

/// `sem 12` a partir del número de periodo (quincenas).
String formatWeek(int period, int weeksPerPeriod) =>
    'sem ${period * weeksPerPeriod}';
