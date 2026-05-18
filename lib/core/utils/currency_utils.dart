import 'package:intl/intl.dart';

class CurrencyUtils {
  static final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double amount) => _fmt.format(amount.toInt());

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount);
  }

  static String formatSigned(double amount, String type) {
    final sign = type == 'pemasukan' ? '+' : '-';
    return '$sign${format(amount.abs())}';
  }
}

class DateUtils2 {
  static String formatDisplay(DateTime date) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(date);

  static String formatMonth(DateTime date) =>
      DateFormat('MMMM yyyy', 'id_ID').format(date);

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);
}
