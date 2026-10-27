import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/partner_profile.dart';
import '../auth/login_screen.dart';
import '../help_screens.dart';
import '../kyc_documents_screen.dart';
import 'business_details_screen.dart';
import 'my_boost_requests_screen.dart';
import 'seller_earnings_screen.dart';
import 'seller_returns_screen.dart';
import 'seller_reviews_screen.dart';
import 'store_profile_screen.dart';

/// The seller's Profile tab, laid out the way partner apps do it: who is
/// signed in at the top (photo, name, email, phone), then the store,
/// money, growth and help screens in grouped cards, and Log out at the end.
class SellerMoreScreen extends StatelessWidget {
  const SellerMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    void open(Widget screen) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(
          l10n.sellerMoreTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          PartnerProfileHeader(auth: auth),
          const SizedBox(height: 20),
          PartnerGroup(
            title: l10n.sellerMoreSectionBusiness,
            rows: [
              PartnerRow(
                icon: Iconsax.shop,
                title: l10n.sellerMoreStore,
                subtitle: l10n.sellerMoreStoreSub,
                onTap: () => open(const StoreProfileScreen()),
              ),
              PartnerRow(
                icon: Iconsax.briefcase,
                title: l10n.sellerMoreBusiness,
                subtitle: l10n.sellerMoreBusinessSub,
                onTap: () => open(const BusinessDetailsScreen()),
              ),
              PartnerRow(
                icon: Iconsax.document_text,
                title: l10n.sellerMoreKyc,
                subtitle: l10n.sellerMoreKycSub,
                onTap: () => open(
                  const KycDocumentsScreen(
                    table: 'seller_documents',
                    ownerColumn: 'seller_id',
                    bucket: 'seller-documents',
                  ),
                ),
              ),
            ],
          ),
          PartnerGroup(
            title: l10n.sellerMoreSectionPerformance,
            rows: [
              PartnerRow(
                icon: Iconsax.wallet_3,
                title: l10n.sellerMoreEarnings,
                subtitle: l10n.sellerMoreEarningsSub,
                onTap: () => open(const SellerEarningsScreen()),
              ),
              PartnerRow(
                icon: Iconsax.rotate_left,
                title: l10n.sellerMoreReturns,
                subtitle: l10n.sellerMoreReturnsSub,
                onTap: () => open(const SellerReturnsScreen()),
              ),
              PartnerRow(
                icon: Iconsax.star,
                title: l10n.sellerMoreReviews,
                subtitle: l10n.sellerMoreReviewsSub,
                onTap: () => open(const SellerReviewsScreen()),
              ),
              PartnerRow(
                icon: Iconsax.chart_2,
                title: l10n.sellerMoreBoosts,
                subtitle: l10n.sellerMoreBoostsSub,
                onTap: () => open(const MyBoostRequestsScreen()),
              ),
            ],
          ),
          PartnerGroup(
            title: l10n.profileSectionHelp,
            rows: [
              PartnerRow(
                icon: Iconsax.message_question,
                title: l10n.profileContactUs,
                onTap: () => open(const ContactUsScreen()),
              ),
              PartnerRow(
                icon: Iconsax.info_circle,
                title: l10n.profileFaq,
                onTap: () => open(const FaqScreen()),
              ),
              PartnerRow(
                icon: Iconsax.shield_tick,
                title: l10n.profilePolicies,
                onTap: () => open(const PoliciesScreen()),
              ),
              PartnerRow(
                icon: Iconsax.document,
                title: l10n.profileTerms,
                onTap: () => open(const TermsScreen()),
              ),
              PartnerRow(
                icon: Iconsax.mobile,
                title: l10n.profileAbout,
                onTap: () => open(const AboutScreen()),
              ),
            ],
          ),
          PartnerGroup(
            rows: [
              PartnerRow(
                icon: Iconsax.logout,
                title: l10n.sellerMoreLogout,
                danger: true,
                onTap: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
