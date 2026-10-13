import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase/supabase.dart' show FunctionException;

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/safe_state.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];
  final Set<String> _deletingIds = {};

  /// Whether the last load failed. A list that could not be fetched is not
  /// an empty list, and the screen says so rather than looking empty.
  bool _loadFailed = false;

  String? get _selfId => SupabaseService.client.auth.currentUser?.id;

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
      final rows = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, phone, role, is_active')
          .order('full_name');
      safeSetState(() => _profiles = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  Future<void> _confirmDelete(Map<String, dynamic> profile) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminUsersDeleteTitle),
        content: Text(
          l10n.adminUsersDeleteBody(profile['full_name'] as String? ?? ''),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.adminUsersCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.dangerColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminUsersDelete,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteUser(profile['id'] as String);
  }

  Future<void> _deleteUser(String userId) async {
    final l10n = AppLocalizations.of(context);
    safeSetState(() => _deletingIds.add(userId));
    try {
      await SupabaseService.client.functions.invoke(
        'admin-delete-user',
        body: {'user_id': userId},
      );
      safeSetState(() => _profiles.removeWhere((p) => p['id'] == userId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text(l10n.adminUsersDeleted,
                maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    } on FunctionException catch (e) {
      final code = e.details is Map ? e.details['error'] as String? : null;
      final message = switch (code) {
        'cannot_delete_self' => l10n.adminUsersErrSelf,
        'referred_by_others' => l10n.adminUsersErrReferred,
        'not_admin' => l10n.adminUsersErrNotAdmin,
        _ => l10n.adminUsersErrGeneric,
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminUsersErrGeneric,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) safeSetState(() => _deletingIds.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.adminUsersTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.adminUsersLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminUsersLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _profiles.isEmpty ? 1 : _profiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (_profiles.isEmpty) {
                return RoleEmpty(
                  icon: Iconsax.people,
                  title: l10n.adminUsersEmptyTitle,
                  message: l10n.adminUsersEmptyBody,
                );
              }
              final profile = _profiles[index];
              final id = profile['id'] as String;
              final isSelf = id == _selfId;
              final isDeleting = _deletingIds.contains(id);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile['full_name'] as String? ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${profile['phone'] ?? ''} · ${profile['role'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDeleting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!isSelf)
                      Pressable(
                          child: IconButton(
                        icon: const Icon(
                          Iconsax.trash,
                          color: AppConstants.dangerColor,
                        ),
                        onPressed: () => _confirmDelete(profile),
                      )),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
