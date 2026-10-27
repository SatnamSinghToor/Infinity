/// Small formatting helpers shared by the cart sheet, product cards and the
/// sticky checkout bar. Indian digit grouping is intentional: `₹1,23,456`
/// rather than `₹123,456`.
String diwaliRupees(int value) {
  if (value < 0) return '-₹${diwaliRupees(-value).substring(1)}';
  final digits = value.toString();
  if (digits.length <= 3) return '₹$digits';
  final last3 = digits.substring(digits.length - 3);
  final head = digits.substring(0, digits.length - 3);
  final buffer = StringBuffer();
  for (var i = 0; i < head.length; i++) {
    final fromEnd = head.length - i;
    buffer.write(head[i]);
    if (fromEnd > 1 && (fromEnd - 1) % 2 == 0) buffer.write(',');
  }
  return '₹${buffer.toString()},$last3';
}

/// Clamps a text scale factor so OS-level large-text settings never break the
/// fixed-height chips and steppers.
double diwaliClampScale(double scale) => scale.clamp(0.85, 1.25);
