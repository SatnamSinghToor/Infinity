class Review {
  final String id;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromSupabaseRow(Map<String, dynamic> row) {
    return Review(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      rating: (row['rating'] as num?)?.toInt() ?? 5,
      comment: row['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
