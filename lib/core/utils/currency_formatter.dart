import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrDecimalFormatter.format(amount);
    }
    return _inrFormatter.format(amount);
  }
}
