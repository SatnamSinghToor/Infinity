import 'package:intl/intl.dart';

/// One row of `payout_requests` (see supabase/payout_requests.sql): a seller
/// or delivery partner asking for money that has been earned, and the admin's
/// decision on it.
class PayoutRequest {
  final String id;
  final String userId;

  /// 'seller' or 'delivery' — which side of the business is being paid.
  final String role;
  final double amount;

  /// Where the money goes, as the partner typed it: a UPI id or an account.
  final String? method;
  final String? note;

  /// 'pending', 'approved', 'rejected' or 'paid'.
  final String status;
  final String? decisionNote;
  final String? paymentReference;
  final DateTime createdAt;

  const PayoutRequest({
    required this.id,
    required this.userId,
    required this.role,
    required this.amount,
    this.method,
    this.note,
    this.status = 'pending',
    this.decisionNote,
    this.paymentReference,
    required this.createdAt,
  });

  String get formattedDate => DateFormat('d MMM yyyy').format(createdAt);

  bool get isPending => status == 'pending';

  /// A human name for who is asking, for the admin's queue.
  String get roleLabel => role == 'delivery' ? 'Delivery partner' : 'Seller';

  factory PayoutRequest.fromSupabaseRow(Map<String, dynamic> row) {
    return PayoutRequest(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      role: row['role'] as String? ?? 'seller',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      method: row['method'] as String?,
      note: row['note'] as String?,
      status: row['status'] as String? ?? 'pending',
      decisionNote: row['decision_note'] as String?,
      paymentReference: row['payment_reference'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
