import 'package:flutter/material.dart';

import '../models/wallet_transaction.dart';
import '../services/supabase_service.dart';

class WalletProvider extends ChangeNotifier {
  final List<WalletTransaction> _transactions = [];
  bool _isLoading = false;

  /// Set when the last load from the backend failed (offline, server error).
  /// An empty list after a failure is not the same as an empty list.
  bool _loadFailed = false;

  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get loadFailed => _loadFailed;

  int get balance => _transactions.fold(
        0,
        (sum, t) => sum + (t.isCredit ? t.amount : -t.amount),
      );

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  /// Forgets the in-memory transactions on sign-out.
  void resetLocal() {
    _transactions.clear();
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    final uid = _userId;
    if (uid == null) return;

    _isLoading = true;
    _loadFailed = false;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('wallet_transactions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      _transactions
        ..clear()
        ..addAll(rows.map(WalletTransaction.fromSupabaseRow));
    } catch (e) {
      debugPrint('Wallet load failed: $e');
      _loadFailed = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Debits [amount] rupees from the signed-in user's wallet via the
  /// `wallet_debit` RPC, which validates the balance server-side under a
  /// single atomic check rather than trusting a client-computed balance.
  /// Returns true on success.
  Future<bool> debit(int amount, {String title = 'Order payment'}) async {
    final uid = _userId;
    if (uid == null || amount <= 0) return false;
    try {
      await SupabaseService.client.rpc(
        'wallet_debit',
        params: {'p_user_id': uid, 'p_amount': amount, 'p_title': title},
      );
      await loadTransactions();
      return true;
    } catch (e) {
      debugPrint('Wallet debit failed: $e');
      return false;
    }
  }
}
