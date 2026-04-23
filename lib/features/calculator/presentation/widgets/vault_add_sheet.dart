import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

const _orange = Color(0xFFFF9F0A);

/// Bottom sheet for choosing how to add media to the vault.
class VaultAddSheet extends StatelessWidget {
  final VoidCallback onAddFromGallery;
  final void Function({required bool isVideo}) onAddFromCamera;

  const VaultAddSheet({
    super.key,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _tile(context, Icons.photo_library, AppLocalizations.instance.t('chooseFromGallery'), () {
            Navigator.pop(context);
            onAddFromGallery();
          }),
          _tile(context, Icons.camera_alt, AppLocalizations.instance.t('takePhoto'), () {
            Navigator.pop(context);
            onAddFromCamera(isVideo: false);
          }),
          _tile(context, Icons.video_camera_front, AppLocalizations.instance.t('recordVideo'), () {
            Navigator.pop(context);
            onAddFromCamera(isVideo: true);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: _orange),
    title: Text(label, style: const TextStyle(color: Colors.white)),
    onTap: onTap,
  );
}

void showVaultAddSheet(
  BuildContext context, {
  required VoidCallback onAddFromGallery,
  required void Function({required bool isVideo}) onAddFromCamera,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2C2C2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => VaultAddSheet(
      onAddFromGallery: onAddFromGallery,
      onAddFromCamera: onAddFromCamera,
    ),
  );
}
