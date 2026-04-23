import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'vault_media_viewer.dart';

const _orange = Color(0xFFFF9F0A);

/// Returns the real extension for a path, unwrapping `.vault` wrapper.
String _realExt(String path) {
  final name = path.split('/').last;
  if (name.endsWith('.vault')) {
    final inner = name.substring(0, name.length - '.vault'.length);
    if (inner.contains('.')) {
      return inner.substring(inner.lastIndexOf('.') + 1).toLowerCase();
    }
  }
  return path.split('.').last.toLowerCase();
}

bool isVaultVideo(String path) {
  final ext = _realExt(path);
  return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'].contains(ext);
}

/// Single grid tile for the vault.
class VaultThumbnail extends StatelessWidget {
  final int index;
  final String path;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const VaultThumbnail({
    super.key,
    required this.index,
    required this.path,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final video = isVaultVideo(path);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          video
              ? VaultVideoThumbnail(path: path)
              : _VaultImageThumbnail(path: path),

          // Play icon overlay for videos
          if (video)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white70,
                size: 36,
              ),
            ),

          // Selection dim + circle
          if (selectionMode)
            Container(
              color: selected
                  ? _orange.withAlpha(80)
                  : Colors.black.withAlpha(30),
            ),
          if (selectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _orange : Colors.transparent,
                  border: Border.all(
                    color: selected ? _orange : Colors.white,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Displays an image from a vault file. Handles both normal image files and
/// `.vault`-wrapped files (whose bytes are read directly — no extension check).
class _VaultImageThumbnail extends StatefulWidget {
  final String path;
  const _VaultImageThumbnail({required this.path});

  @override
  State<_VaultImageThumbnail> createState() => _VaultImageThumbnailState();
}

class _VaultImageThumbnailState extends State<_VaultImageThumbnail> {
  late final Future<List<int>> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = File(widget.path).readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data == null) {
          return Container(color: const Color(0xFF2C2C2E));
        }
        return Image.memory(
          Uint8List.fromList(snapshot.data!),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFF2C2C2E),
            child: const Icon(Icons.broken_image, color: Colors.white30),
          ),
        );
      },
    );
  }
}
