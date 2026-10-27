class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? orderId;
  final String? productId;

  /// When the user archived it (`notifications.archived_at`); null while it
  /// is still in the inbox.
  final DateTime? archivedAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.orderId,
    this.productId,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;

  factory AppNotification.fromSupabaseRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      type: row['type'] as String? ?? 'general',
      title: row['title'] as String? ?? '',
      message: (row['message'] as String?) ?? (row['body'] as String?) ?? '',
      isRead: row['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      orderId: row['order_id'] as String?,
      productId: row['product_id'] as String?,
      archivedAt: DateTime.tryParse(row['archived_at'] as String? ?? ''),
    );
  }

  /// [clearArchived] exists because a plain `archivedAt: null` can't be told
  /// apart from "not passed".
  AppNotification copyWith({
    bool? isRead,
    DateTime? archivedAt,
    bool clearArchived = false,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      orderId: orderId,
      productId: productId,
      archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
    );
  }
}
