import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/wallet_transaction.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
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

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.walletTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => context.read<WalletProvider>().loadTransactions(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppConstants.headerGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.walletBalanceLabel,
                    style: GoogleFonts.poppins(
                      color:
                          AppConstants.textPrimaryColor.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupees(wallet.balance),
                    style: GoogleFonts.poppins(
                      color: AppConstants.textPrimaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.walletHistoryTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.walletEmpty,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...wallet.transactions.map((t) => _TransactionTile(t)),
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
    final isCredit = transaction.isCredit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Iconsax.arrow_down_2 : Iconsax.arrow_up_3,
              color: isCredit ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${formatRupees(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
