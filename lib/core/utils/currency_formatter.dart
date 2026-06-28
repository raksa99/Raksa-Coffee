import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const double usdToKhrRate = 4000.0;

  static final NumberFormat _usdFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _khrFormat = NumberFormat('#,##0');

  static String formatUsd(double usdAmount) {
    return _usdFormat.format(usdAmount);
  }

  static String formatKhr(double usdAmount) {
    final khrAmount = usdAmount * usdToKhrRate;
    return '${_khrFormat.format(khrAmount)} ៛';
  }

  static String formatDual(double usdAmount) {
    return '${formatUsd(usdAmount)} (${formatKhr(usdAmount)})';
  }

  // Fallback alias for existing displays
  static String format(double amount) {
    return formatDual(amount);
  }
}
