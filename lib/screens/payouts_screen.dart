import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../models/payout_request.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/safe_state.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../widgets/pressable.dart';

/// Payouts, from the partner's side: what is owed, what has been asked for,
/// and what was decided. Shared by the seller and the delivery partner,
/// because the difference between them is only which table their earnings
/// live in — and that is the server's business, not this screen's.
///
/// The balance comes from `payout_balance()` and a new request goes through
/// `request_payout()`: both live in the database (see
/// supabase/payout_requests.sql), so the amount is checked where the money is,
/// not in a widget that could be edited.
class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  bool _isLoading = true;

  /// Whether the last load failed: said out loud, with a way to try again,
  /// instead of passing a failed request off as "nothing owed".
  bool _loadFailed = false;
  List<PayoutRequest> _requests = [];
  double _earned = 0;
  double _outstanding = 0;
  bool _requesting = false;

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
      final client = SupabaseService.client;
      final rows = await client
          .from('payout_requests')
          .select()
          .order('created_at', ascending: false);
      final balance = await client.rpc('payout_balance');

      safeSetState(() {
        _requests = [
          for (final row in rows)
            PayoutRequest.fromSupabaseRow(Map<String, dynamic>.from(row)),
        ];
        // The function returns one row; an empty list means this account is
        // not a seller or a delivery partner.
        if (balance is List && balance.isNotEmpty) {
          final row = Map<String, dynamic>.from(balance.first as Map);
          _earned = (row['earned'] as num?)?.toDouble() ?? 0;
          _outstanding = (row['outstanding'] as num?)?.toDouble() ?? 0;
        } else {
          _earned = 0;
          _outstanding = 0;
        }
      });
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  double get _available =>
      (_earned - _outstanding).clamp(0.0, double.infinity).toDouble();

  Future<void> _askForPayout() async {
    final amount = TextEditingController(
      text: _available > 0 ? _available.toStringAsFixed(0) : '',
    );
    final method = TextEditingController();
    final note = TextEditingController();

    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request a payout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available ${formatRupees(_available)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: method,
                decoration: const InputDecoration(
                  labelText: 'UPI id or bank account',
                  helperText: 'Where we should send it',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send request',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );

    if (send != true || !mounted) return;

    final parsed = double.tryParse(amount.text.trim().replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      _tell('Enter an amount first.');
      return;
    }

    safeSetState(() => _requesting = true);
    try {
      await SupabaseService.client.rpc('request_payout', params: {
        'p_amount': parsed,
        'p_method': method.text.trim(),
        'p_note': note.text.trim(),
      });
      if (!mounted) return;
      _tell('Payout requested. It shows as pending until it is approved.');
      await _load();
    } catch (e) {
      // The server refuses anything above what is really owed, and says by
      // how much: pass that on rather than a generic failure.
      _tell(_readableError(e));
    } finally {
      if (mounted) safeSetState(() => _requesting = false);
    }
  }

  /// A Postgres error, in words. `OVER_BALANCE:123.5` comes from
  /// `request_payout` in supabase/payout_requests.sql.
  String _readableError(Object error) {
    final text = error.toString();
    if (text.contains('OVER_BALANCE')) {
      final tail = text.split('OVER_BALANCE:').last;
      final left = double.tryParse(tail.split(RegExp(r'[^0-9.]')).first) ?? 0;
      return 'That is more than you have available '
          '(${formatRupees(left)}).';
    }
    if (text.contains('NOT_A_PAYOUT_ROLE')) {
      return 'This account cannot request a payout.';
    }
    if (text.contains('request_payout') && text.contains('does not exist')) {
      return 'Payouts are not set up on the server yet. '
          'Run supabase/payout_requests.sql in Supabase.';
    }
    return "Couldn't send the request. Check your connection and try again.";
  }

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'paid':
        return AppConstants.successColor;
      case 'rejected':
        return AppConstants.dangerColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'paid':
        return 'Paid';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title:
            const Text('Payouts', maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: 'Working out what is owed…',
        failed: _loadFailed,
        errorTitle: "Couldn't load your payouts",
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _balanceCard(),
              const SizedBox(height: 16),
              SizedBox(
                // Disabled rather than hidden: a partner with nothing
                // available should still see how a payout is asked for.
                height: 48,
                child: Pressable(
                    child: ElevatedButton.icon(
                  onPressed:
                      (_available <= 0 || _requesting) ? null : _askForPayout,
                  icon: const Icon(Iconsax.wallet_3, size: 18),
                  label: Text(
                    _requesting ? 'Sending…' : 'Request payout',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_requests.isEmpty)
                const RoleEmptyNote(
                  icon: Iconsax.wallet_3,
                  message: 'Nothing requested yet. Payouts you ask for show '
                      'up here with the admin\'s decision.',
                )
              else
                ..._requests.map(_requestCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppConstants.headerGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available to withdraw',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupees(_available),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Earned ${formatRupees(_earned)} · already asked for '
            '${formatRupees(_outstanding)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(PayoutRequest request) {
    final color = _statusColor(request.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatRupees(request.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                request.formattedDate,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
          if (request.method != null && request.method!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'To ${request.method}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
          if (request.decisionNote != null &&
              request.decisionNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.decisionNote!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
          if (request.paymentReference != null &&
              request.paymentReference!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reference ${request.paymentReference}',
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
