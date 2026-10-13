import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/order_provider.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/role_common.dart';
import '../widgets/pressable.dart';

/// The pages behind Profile's Help & Support and About & Community rows.

/// A page of headed paragraphs (About, Policies, Terms).
class InfoScreen extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;

  const InfoScreen({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          for (final (heading, body) in sections) ...[
            Text(
              heading,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InfoScreen(
      title: l10n.helpAboutTitle,
      sections: [
        (l10n.helpAboutDugguHeading, l10n.helpAboutDugguBody),
        (l10n.helpAboutStoresHeading, l10n.helpAboutStoresBody),
        (
          l10n.helpAboutNeighbourhoodsHeading,
          l10n.helpAboutNeighbourhoodsBody,
        ),
      ],
    );
  }
}

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fee = formatRupees(OrderProvider.baseDeliveryFee);
    final threshold = formatRupees(OrderProvider.freeDeliveryThreshold);
    return InfoScreen(
      title: l10n.helpPoliciesTitle,
      sections: [
        (l10n.helpPolicyPrivacyHeading, l10n.helpPolicyPrivacyBody),
        (l10n.helpPolicyPaymentsHeading, l10n.helpPolicyPaymentsBody),
        (
          l10n.helpPolicyDeliveryHeading,
          l10n.helpPolicyDeliveryBody(fee, threshold),
        ),
        (l10n.helpPolicyRefundsHeading, l10n.helpPolicyRefundsBody),
        (l10n.helpPolicyReturnsHeading, l10n.helpPolicyReturnsBody),
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InfoScreen(
      title: l10n.helpTermsTitle,
      sections: [
        (l10n.helpTermsUsingHeading, l10n.helpTermsUsingBody),
        (l10n.helpTermsPricesHeading, l10n.helpTermsPricesBody),
        (l10n.helpTermsCouponsHeading, l10n.helpTermsCouponsBody),
        (l10n.helpTermsFairUseHeading, l10n.helpTermsFairUseBody),
      ],
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static List<(String, String)> _faqs(AppLocalizations l10n) {
    final fee = formatRupees(OrderProvider.baseDeliveryFee);
    final threshold = formatRupees(OrderProvider.freeDeliveryThreshold);
    return [
      (l10n.helpFaqDeliveryTimeQuestion, l10n.helpFaqDeliveryTimeAnswer),
      (
        l10n.helpFaqChargesQuestion,
        l10n.helpFaqChargesAnswer(fee, threshold),
      ),
      (l10n.helpFaqPayQuestion, l10n.helpFaqPayAnswer),
      (l10n.helpFaqCouponsQuestion, l10n.helpFaqCouponsAnswer),
      (l10n.helpFaqCancelQuestion, l10n.helpFaqCancelAnswer),
      (l10n.helpFaqWrongItemQuestion, l10n.helpFaqWrongItemAnswer),
      (
        l10n.helpFaqReferralQuestion,
        l10n.helpFaqReferralAnswer(formatRupees(50)),
      ),
      (
        l10n.helpFaqMissingProductQuestion,
        l10n.helpFaqMissingProductAnswer,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final faqs = _faqs(l10n);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.helpFaqTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          for (final (question, answer) in faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4E4E4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Text(
                      answer,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Saves a message from the signed-in person to `app_feedback`.
Future<bool> _sendFeedback({
  required String kind,
  String? title,
  String? message,
  int? rating,
}) async {
  try {
    await SupabaseService.client.from('app_feedback').insert({
      'kind': kind,
      'title': title,
      'message': message,
      'rating': rating,
    });
    return true;
  } catch (_) {
    return false;
  }
}

class _FormShell extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormShell({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        children: children,
      ),
    );
  }
}

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    final ok = await _sendFeedback(
      kind: 'contact',
      title: _subject.text.trim(),
      message: _message.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.helpContactSent : l10n.helpSendFailed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FormShell(
      title: l10n.helpContactTitle,
      children: [
        Text(
          l10n.helpContactIntro,
          style: const TextStyle(color: AppConstants.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _subject,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.helpContactSubject),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _message,
          minLines: 5,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: l10n.helpContactMessage,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: Pressable(
              child: ElevatedButton(
            onPressed: _sending ? null : _send,
            child: Text(
              _sending ? l10n.helpSending : l10n.helpContactSend,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ),
      ],
    );
  }
}

class ProductRequestsScreen extends StatefulWidget {
  const ProductRequestsScreen({super.key});

  @override
  State<ProductRequestsScreen> createState() => _ProductRequestsScreenState();
}

class _ProductRequestsScreenState extends State<ProductRequestsScreen> {
  final _name = TextEditingController();
  final _details = TextEditingController();
  bool _sending = false;
  List<Map<String, dynamic>> _mine = [];

  /// Whether the request list failed to load. A failed read is not "no
  /// requests", so the screen says so instead of hiding the list.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final rows = await SupabaseService.client
          .from('app_feedback')
          .select('title, message, status, created_at')
          .eq('kind', 'product_request')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _mine = [
              for (final row in rows) Map<String, dynamic>.from(row),
            ]);
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _send() async {
    if (_name.text.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    final ok = await _sendFeedback(
      kind: 'product_request',
      title: _name.text.trim(),
      message: _details.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _name.clear();
      _details.clear();
      await _load();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.helpRequestsSent : l10n.helpSendFailed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FormShell(
      title: l10n.helpRequestsTitle,
      children: [
        Text(
          l10n.helpRequestsIntro,
          style: const TextStyle(color: AppConstants.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.helpRequestsName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _details,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.helpRequestsDetails,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: Pressable(
              child: ElevatedButton(
            onPressed: _sending ? null : _send,
            child: Text(
              _sending ? l10n.helpSending : l10n.helpRequestsSend,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ),
        if (_loadFailed) ...[
          const SizedBox(height: 20),
          RoleInlineError(
            message: l10n.helpRequestsLoadFailed,
            onRetry: _load,
          ),
        ],
        if (_mine.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            l10n.helpRequestsMine,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final row in _mine)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E4E4)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.box, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row['title'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    row['status'] == 'done'
                        ? l10n.helpRequestDone
                        : l10n.helpRequestOpen,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: row['status'] == 'done'
                          ? AppConstants.successColor
                          : AppConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Rate Us: stars and an optional note, saved to `app_feedback`.
Future<void> showRateUsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _RateUsSheet(),
  );
}

class _RateUsSheet extends StatefulWidget {
  const _RateUsSheet();

  @override
  State<_RateUsSheet> createState() => _RateUsSheetState();
}

class _RateUsSheetState extends State<_RateUsSheet> {
  int _stars = 0;
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_stars == 0) return;
    setState(() => _sending = true);
    final ok = await _sendFeedback(
      kind: 'rating',
      rating: _stars,
      message: _note.text.trim(),
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.helpRateThanks : l10n.helpSendFailed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.helpRateTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Pressable(
                      child: IconButton(
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 38,
                      color: AppConstants.accentColor,
                    ),
                  )),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.helpRateNote,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Pressable(
                  child: ElevatedButton(
                onPressed: _stars == 0 || _sending ? null : _send,
                child: Text(
                  l10n.helpRateSubmit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Share App: opens the phone's share sheet.
Future<void> shareApp(AppLocalizations l10n) {
  return Share.share(l10n.helpShareMessage);
}
