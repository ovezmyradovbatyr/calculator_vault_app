import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

const _orange = Color(0xFFFF9F0A);

/// Bottom action bar shown in selection mode with Delete and Restore buttons.
class VaultSelectionBar extends StatelessWidget {
  final bool canAct;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const VaultSelectionBar({
    super.key,
    required this.canAct,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(AppLocalizations.instance.t('delete')),
                onPressed: canAct ? onDelete : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.restore),
                label: Text(AppLocalizations.instance.t('restore')),
                onPressed: canAct ? onRestore : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
