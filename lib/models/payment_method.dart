class PaymentMethod {
  final String id;
  final String type; // 'CARD' or 'UPI'
  final String label;
  final String detail;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.detail,
    required this.isDefault,
  });

  factory PaymentMethod.fromSupabaseRow(Map<String, dynamic> row) {
    return PaymentMethod(
      id: row['id'] as String,
      type: row['type'] as String? ?? 'UPI',
      label: row['label'] as String? ?? '',
      detail: row['detail'] as String? ?? '',
      isDefault: row['is_default'] as bool? ?? false,
    );
  }
}
