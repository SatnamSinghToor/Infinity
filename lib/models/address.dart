/// A saved delivery address (`addresses` table).
class Address {
  /// The row id. Empty for an address that hasn't been saved yet — the
  /// database assigns the uuid.
  final String id;

  /// "Home", "Work" or "Other".
  final String label;

  final String fullAddress;

  /// Where the address is on the map (from live location or the map picker);
  /// null when it was only typed in.
  final double? lat;
  final double? lng;

  final bool isDefault;

  /// Who to deliver to. The addresses table has no columns for these — they
  /// come from the user's profile (or the checkout form) and are never saved
  /// with the address.
  final String fullName;
  final String phone;

  const Address({
    required this.id,
    required this.fullAddress,
    this.label = 'Home',
    this.lat,
    this.lng,
    this.isDefault = false,
    this.fullName = '',
    this.phone = '',
  });

  bool get hasPin => lat != null && lng != null;

  Address copyWith({
    String? label,
    String? fullAddress,
    double? lat,
    double? lng,
    bool? isDefault,
    String? fullName,
    String? phone,
  }) {
    return Address(
      id: id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
    );
  }

  /// The row to insert/update for [userId]. `id` is left out on purpose so
  /// new rows get the database's uuid.
  Map<String, dynamic> toRow(String userId) {
    return {
      'user_id': userId,
      'label': label,
      'full_address': fullAddress,
      'is_default': isDefault,
      // The table carries the coordinates twice (lat/lng and
      // latitude/longitude); keep both in step.
      'lat': lat,
      'lng': lng,
      'latitude': lat,
      'longitude': lng,
    };
  }

  factory Address.fromRow(
    Map<String, dynamic> row, {
    String fullName = '',
    String phone = '',
  }) {
    double? number(dynamic v) => v == null ? null : (v as num).toDouble();
    return Address(
      id: row['id'] as String? ?? '',
      label: (row['label'] as String?)?.trim().isNotEmpty == true
          ? row['label'] as String
          : 'Home',
      fullAddress: row['full_address'] as String? ?? '',
      lat: number(row['lat'] ?? row['latitude']),
      lng: number(row['lng'] ?? row['longitude']),
      isDefault: row['is_default'] as bool? ?? false,
      fullName: fullName,
      phone: phone,
    );
  }
}
