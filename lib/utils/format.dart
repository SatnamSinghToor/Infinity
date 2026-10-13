import 'package:intl/intl.dart';

/// Formats [amount] as Indian rupees with lakh/crore grouping: ₹1,15,000 —
/// no decimals for whole amounts, two for the rest (₹99.50).
String formatRupees(num amount) {
  final whole = amount == amount.roundToDouble();
  final formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_IN',
    decimalDigits: whole ? 0 : 2,
  );
  return '₹${formatter.format(amount)}';
}
