import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Duggu';
  static const String tagline = 'Store me same day delivery';

  // Colors — premium orange / cream / black / white glass theme
  static const Color primaryColor = Color(0xFFFF6A00); // vivid orange
  static const Color accentColor = Color(0xFFF2711C); // brand orange
  static const Color blackColor = Color(0xFF0B0B0F);
  static const Color backgroundColor = Color(0xFFF7F7F7); // light neutral grey
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF1A1A1A);
  static const Color textSecondaryColor = Color(0xFF6E6E6E);
  static const Color dangerColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7F7)],
  );

  /// Home's soft butter-yellow header, distinct from the plain utility-page
  /// headers while keeping the same warm Duggu palette.
  static const LinearGradient homeHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF7D8), Color(0xFFFFE7A1)],
  );

  // Category list
  /// Well-known company brands, suggested to sellers when they add a product
  /// (they can still type any other brand).
  static const List<String> popularBrands = [
    'Apple',
    'Samsung',
    'Sony',
    'LG',
    'HP',
    'Dell',
    'Lenovo',
    'Asus',
    'Xiaomi',
    'OnePlus',
    'realme',
    'boAt',
    'Nike',
    'Adidas',
    'Puma',
    "Levi's",
    'Nestlé',
    'Amul',
    'Britannia',
    'Parle',
    'Tata',
    'ITC',
    "Haldiram's",
    'Maggi',
    "Lay's",
    'Coca-Cola',
    'Pepsi',
    'Cadbury',
    'Mother Dairy',
    'Dabur',
    'Patanjali',
    'Hindustan Unilever',
    'Colgate',
    'Dettol',
    'Godrej',
    'Surf Excel',
    'Tide',
    'Fortune',
    'Aashirvaad',
    'MDH',
    'Everest',
    "Kellogg's",
    'Bisleri',
    'Red Bull',
  ];
}
