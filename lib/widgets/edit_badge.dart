import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../utils/constants.dart';
import 'pressable.dart';

/// Whether the person using the app is an admin with edit mode switched on.
bool isEditing(BuildContext context) =>
    context.watch<EditModeProvider>().enabled &&
    context.watch<AuthProvider>().role == UserRole.admin;

/// One thing an admin can do to the card they tapped the pencil on.
class EditTool {
  final IconData icon;
  final String label;
  final String? hint;

  /// Red, for things that can't be undone.
  final bool danger;
  final Future<void> Function() run;

  const EditTool({
    required this.icon,
    required this.label,
    required this.run,
    this.hint,
    this.danger = false,
  });
}

/// A small pencil on the corner of a card while an admin has edit mode on.
/// Tapping it opens a sheet with only the tools for this card ([tools] is
/// loaded when the sheet opens, so it can look up the card's data first).
/// For everyone else, and with edit mode off, it is just [child].
class EditPencil extends StatelessWidget {
  final Widget child;

  /// What the sheet is headed with: the card's name.
  final String title;
  final Future<List<EditTool>> Function() tools;

  /// Where the pencil sits on [child].
  final Alignment alignment;

  const EditPencil({
    super.key,
    required this.child,
    required this.title,
    required this.tools,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing(context)) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Pressable(
                  child: Material(
                color: AppConstants.primaryColor,
                elevation: 3,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showEditSheet(context, title, tools),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Iconsax.edit, size: 15, color: Colors.white),
                  ),
                ),
              )),
            ),
          ),
        ),
      ],
    );
  }
}

/// The sheet of tools for one card.
Future<void> showEditSheet(
  BuildContext context,
  String title,
  Future<List<EditTool>> Function() loadTools,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheet) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: FutureBuilder<List<EditTool>>(
            future: loadTools(),
            builder: (context, snapshot) {
              final l10n = AppLocalizations.of(context);
              final tools = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.editSheetTitle(title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (tools == null && !snapshot.hasError)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (tools == null || tools.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(l10n.editNothingToEdit,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    )
                  else
                    for (final tool in tools)
                      ListTile(
                        leading: Icon(
                          tool.icon,
                          color: tool.danger
                              ? AppConstants.dangerColor
                              : AppConstants.primaryColor,
                        ),
                        title: Text(
                          tool.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                tool.danger ? AppConstants.dangerColor : null,
                          ),
                        ),
                        subtitle: tool.hint == null ? null : Text(tool.hint!),
                        onTap: () async {
                          Navigator.pop(sheet);
                          await tool.run();
                        },
                      ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

/// The admin's "Edit mode" switch, floating over the store.
class EditModeSwitch extends StatelessWidget {
  const EditModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != UserRole.admin) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final on = context.watch<EditModeProvider>().enabled;
    return FloatingActionButton.extended(
      heroTag: 'edit-mode-switch',
      backgroundColor: on ? AppConstants.primaryColor : Colors.black87,
      foregroundColor: Colors.white,
      onPressed: () => context.read<EditModeProvider>().toggle(),
      icon: Icon(on ? Iconsax.tick_circle : Iconsax.edit, size: 20),
      label: Text(on ? l10n.editModeOn : l10n.editModeOff,
          maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
