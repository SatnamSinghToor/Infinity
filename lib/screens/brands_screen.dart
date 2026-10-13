import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'main_shell.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../utils/safe_state.dart';

/// "Shop by Brand" — lists brands from the `brands` table and filters the
/// home product grid by the tapped brand's name (products.brand is a plain
/// text column, matched by the seller when they add a product).
class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: a brand list we could not fetch is not
  /// the same as a shop with no brands.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows =
          await SupabaseService.client.from('brands').select().order('name');
      safeSetState(() => _brands = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  void _selectBrand(BuildContext context, String name) {
    context.read<ProductProvider>().setBrand(name);
    MainShell.goTo(context, MainShell.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loadFailed && _brands.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: GradientAppBar(
            title: Text(l10n.brandsTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: RoleError(
          title: l10n.brandsLoadFailed,
          onRetry: _load,
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.brandsTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _brands.isEmpty
              ? Center(child: Text(l10n.brandsEmpty))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _brands.length,
                  itemBuilder: (context, index) {
                    final name = _brands[index]['name'] as String? ?? '';
                    return GestureDetector(
                      onTap: () => _selectBrand(context, name),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppConstants.primaryColor,
                                    AppConstants.accentColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Icon(
                                  Iconsax.shopping_bag,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
