class WalletTransaction {
  final String id;
  final String title;
  final int amount;
  final String type; // 'CREDIT' or 'DEBIT'
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  bool get isCredit => type == 'CREDIT';

  factory WalletTransaction.fromSupabaseRow(Map<String, dynamic> row) {
    return WalletTransaction(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      amount: (row['amount'] as num?)?.toInt() ?? 0,
      type: row['type'] as String? ?? 'CREDIT',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
