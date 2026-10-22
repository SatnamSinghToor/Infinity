import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/wallet_transaction.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../utils/format.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wallet = context.watch<WalletProvider>();
    final t = context.tokens;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.walletTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => context.read<WalletProvider>().loadTransactions(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            // The balance: a labelled plate with the amount as its hero.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppConstants.headerGradient,
                borderRadius: AppRadius.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Iconsax.wallet_3,
                      size: 22,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.walletBalanceLabel,
                        style: GoogleFonts.poppins(
                          color: t.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        formatRupees(wallet.balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: t.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.walletHistoryTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (wallet.isLoading && wallet.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (wallet.loadFailed)
              RoleError(
                title: l10n.walletLoadFailed,
                onRetry: wallet.loadTransactions,
              )
            else if (wallet.transactions.isEmpty)
              // Say what an empty wallet means, and what puts money in it,
              // rather than a bare line of grey text.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: RoleEmpty(
                  icon: Iconsax.receipt,
                  title: l10n.walletEmpty,
                  message: l10n.walletEmptyBody,
                ),
              )
            else
              ...wallet.transactions.map((t2) => _TransactionTile(t2)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile(this.transaction);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isCredit = transaction.isCredit;
    final colour = isCredit ? t.success : t.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colour.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Iconsax.arrow_down_2 : Iconsax.arrow_up_3,
              color: colour,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DateFormat('d MMM yyyy').format(transaction.createdAt),
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${isCredit ? '+' : '-'}${formatRupees(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}
