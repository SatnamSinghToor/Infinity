import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Infinity';
  static const String tagline =
      'Same-day delivery for everything your home needs';

  // Colors — Orange grocery theme
  static const Color primaryColor = Color(0xFFFF5A00); // Mirinda orange
  static const Color accentColor = Color(0xFFFF5A00); // Same as primary
  static const Color blackColor = Color(0xFF0B0B0F);
  static const Color backgroundColor = Color(0xFFF7F7F7); // light neutral grey
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF20252E); // Near-black
  static const Color textSecondaryColor = Color(0xFF6E6E6E);
  static const Color dangerColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  // Grocery-specific colors
  static const Color vegGreen = Color(0xFF237A35); // Vegetarian badge
  static const Color nonVegRed = Color(0xFFD32F2F); // Non-vegetarian
  static const Color discountBlue = Color(0xFF2F6FC9); // Discount text
  static const Color cardBorder = Color(0xFFE3E6EB); // Light grey hairline
  static const Color imageBackground = Color(0xFFF8F8F8); // Very light neutral

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7F7)],
  );

  /// Home's soft butter-yellow header, distinct from the plain utility-page
  /// headers while keeping the same warm Infinity palette.
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

  // Card radii
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double imageRadius = 20.0;

  // Breakpoints
  static const double mobileBreakpoint = 500;
  static const double tabletBreakpoint = 899;
}
