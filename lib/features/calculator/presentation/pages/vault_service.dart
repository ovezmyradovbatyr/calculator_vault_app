import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultEntry {
  final String path;
  final String? assetId;
  final String? relativePath;

  /// Original filename as it existed in the gallery, e.g. "IMG_20260420.jpg".
  final String? originalTitle;

  const VaultEntry({
    required this.path,
    this.assetId,
    this.relativePath,
    this.originalTitle,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    if (assetId != null) 'assetId': assetId,
    if (relativePath != null) 'relativePath': relativePath,
    if (originalTitle != null) 'originalTitle': originalTitle,
  };

  factory VaultEntry.fromJson(Map<String, dynamic> j) => VaultEntry(
    path: j['path'] as String,
    assetId: j['assetId'] as String?,
    relativePath: j['relativePath'] as String?,
    originalTitle: j['originalTitle'] as String?,
  );

  /// Legacy support: plain path string (no JSON)
  factory VaultEntry.fromRaw(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return VaultEntry.fromJson(m);
    } catch (_) {
      return VaultEntry(path: raw);
    }
  }

  String toRaw() => jsonEncode(toJson());
}

/// All file I/O and MediaStore operations for the Secret Vault.
class VaultService {
  static const _prefsKey = 'secret_vault_media';
  final _picker = ImagePicker();

  // ── vault directory ──────────────────────────────────────────────────────

  Future<String> getVaultDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/secret_vault');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  // ── permissions ──────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state.isAuth;
  }

  // ── MANAGE_MEDIA permission (Android 12+) ────────────────────────────────

  static const _mediaCh = MethodChannel('com.example.calculator_app/media');
  static const _manageMediaHandledKey = 'vault_manage_media_handled';

  /// Returns true if MANAGE_MEDIA is granted (silent deletion on Android 12+).
  Future<bool> isManageMediaGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _mediaCh.invokeMethod<bool>('hasManageMedia') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system dialog to grant MANAGE_MEDIA permission.
  Future<void> requestManageMediaPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _mediaCh.invokeMethod('requestManageMedia');
    } catch (_) {}
  }

  Future<bool> hasHandledManageMedia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_manageMediaHandledKey) ?? false;
  }

  Future<void> setHandledManageMedia() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manageMediaHandledKey, true);
  }

  // ── persistence ──────────────────────────────────────────────────────────

  Future<List<VaultEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    final existing = saved
        .map((r) => VaultEntry.fromRaw(r))
        .where((e) => File(e.path).existsSync())
        .toList();
    if (existing.length != saved.length) {
      await _saveEntries(existing);
    }
    return existing;
  }

  Future<void> _saveEntries(List<VaultEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => e.toRaw()).toList(),
    );
  }

  // ── convenience wrappers used by the page ────────────────────────────────

  /// Returns only the file paths (for backwards compat with the grid).
  Future<List<String>> loadMedia() async {
    final entries = await loadEntries();
    return entries.map((e) => e.path).toList();
  }

  Future<void> saveMedia(List<String> paths) async {
    // Called by the page after reorder / delete — we must preserve metadata.
    final existing = await loadEntries();
    final byPath = {for (final e in existing) e.path: e};
    final updated = paths.map((p) => byPath[p] ?? VaultEntry(path: p)).toList();
    await _saveEntries(updated);
  }

  // ── internal helpers ─────────────────────────────────────────────────────

  /// Ensures a `.nomedia` file exists in the vault dir so the media scanner
  /// never indexes any file inside it — even if an extension is wrong.
  Future<void> _ensureNoMedia(String vaultDir) async {
    final nm = File('$vaultDir/.nomedia');
    if (!nm.existsSync()) await nm.create();
  }

  /// Moves [srcPath] into [vaultDir] as `<originalBaseName>.<origExt>.vault`.
  /// Using the original filename keeps it recognisable and avoids duplication.
  /// A numeric suffix is added only if the name already exists.
  Future<String> _copyToVault(
    String srcPath,
    String vaultDir, {
    String? originalTitle,
  }) async {
    await _ensureNoMedia(vaultDir);

    // Derive base and extension from originalTitle when available.
    String base;
    String ext;
    if (originalTitle != null && originalTitle.isNotEmpty) {
      final dot = originalTitle.lastIndexOf('.');
      if (dot >= 0) {
        base = originalTitle.substring(0, dot);
        ext = originalTitle.substring(dot); // e.g. ".jpg"
      } else {
        base = originalTitle;
        ext = srcPath.contains('.')
            ? srcPath.substring(srcPath.lastIndexOf('.'))
            : '.jpg';
      }
    } else {
      ext = srcPath.contains('.')
          ? srcPath.substring(srcPath.lastIndexOf('.'))
          : '.jpg';
      base = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Avoid collisions: IMG_20260420.jpg.vault, IMG_20260420_1.jpg.vault …
    String name = '$base$ext.vault';
    String dest = '$vaultDir/$name';
    int counter = 1;
    while (File(dest).existsSync()) {
      name = '${base}_$counter$ext.vault';
      dest = '$vaultDir/$name';
      counter++;
    }

    await File(srcPath).copy(dest);
    return dest;
  }

  /// Returns the real media extension embedded in a vault filename.
  /// e.g. `1234567890.jpg.vault` → `.jpg`
  String _originalExt(String vaultPath) {
    final name = vaultPath.split('/').last; // e.g. 1234567890.jpg.vault
    if (name.endsWith('.vault')) {
      final withoutVault = name.substring(0, name.length - '.vault'.length);
      if (withoutVault.contains('.')) {
        return withoutVault.substring(withoutVault.lastIndexOf('.'));
      }
    }
    // Legacy: file has no .vault wrapper — use its own extension.
    return vaultPath.contains('.')
        ? vaultPath.substring(vaultPath.lastIndexOf('.'))
        : '.jpg';
  }

  // ── add via photo_manager ────────────────────────────────────────────────

  /// Takes [AssetEntity] objects (from the custom gallery picker) and:
  ///  1. Copies the file bytes to vault with a `.vault` extension.
  ///  2. Deletes the original from MediaStore using the asset's own ID
  ///     (no title search — guaranteed to delete the correct file).
  Future<List<VaultEntry>> addAssetsToVault(List<AssetEntity> assets) async {
    final vaultDir = await getVaultDir();
    final results = <VaultEntry>[];

    final idsToDelete = <String>[];

    for (final asset in assets) {
      try {
        // Get the original file (may be a cached copy on Android 10+, but
        // the bytes are the real file bytes).
        final originFile = await asset.originFile;
        if (originFile == null) continue;

        final originalTitle = asset.title ?? originFile.uri.pathSegments.last;

        final vaultPath = await _copyToVault(
          originFile.path,
          vaultDir,
          originalTitle: originalTitle,
        );

        idsToDelete.add(asset.id);
        results.add(
          VaultEntry(
            path: vaultPath,
            assetId: asset.id,
            relativePath: asset.relativePath,
            originalTitle: originalTitle,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    // Удаляем все оригиналы одним вызовом → на Android 11+ один системный
    // диалог на всю операцию вместо диалога на каждый файл.
    if (idsToDelete.isNotEmpty) {
      await PhotoManager.editor.deleteWithIds(idsToDelete);
    }

    return results;
  }

  /// Pick a single image or video from the CAMERA (gallery is handled by the
  /// custom picker — see [addAssetsToVault]).
  Future<VaultEntry?> pickFromCamera({required bool isVideo}) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: ImageSource.camera)
          : await _picker.pickImage(source: ImageSource.camera);
      if (file == null) return null;

      final vaultDir = await getVaultDir();
      final vaultPath = await _copyToVault(file.path, vaultDir);

      // Delete the picker's temp file.
      try {
        await File(file.path).delete();
      } catch (_) {}

      return VaultEntry(path: vaultPath);
    } catch (_) {
      return null;
    }
  }

  // ── legacy wrappers (kept for any residual callers) ───────────────────────

  Future<List<VaultEntry>> pickFromGallery() async => [];

  /// Pick a single image or video (camera or gallery).
  Future<VaultEntry?> pickSingle(
    ImageSource source, {
    required bool isVideo,
  }) async {
    if (source == ImageSource.camera) {
      return pickFromCamera(isVideo: isVideo);
    }
    // Gallery picking should go through showVaultGalleryPicker + addAssetsToVault.
    return null;
  }

  Future<List<String>> pickMultiple() async => [];

  /// Restores vault file back into its original folder (relativePath).
  Future<void> restoreToGallery(String vaultPath) async {
    if (!await requestPermission()) return;

    final entries = await loadEntries();
    final entry = entries.firstWhere(
      (e) => e.path == vaultPath,
      orElse: () => VaultEntry(path: vaultPath),
    );

    try {
      // If the file has a .vault extension, create a temp copy with the
      // real extension so PhotoManager can recognise and save it correctly.
      File sourceFile = File(vaultPath);
      File? tempFile;

      if (vaultPath.endsWith('.vault')) {
        // Restore with the original filename so gallery gets the right name.
        final restoreName =
            entry.originalTitle ??
            (() {
              final realExt = _originalExt(vaultPath);
              return 'restored$realExt';
            })();
        final tmpPath =
            '${vaultPath.substring(0, vaultPath.lastIndexOf('/'))}/$restoreName';
        tempFile = await sourceFile.copy(tmpPath);
        sourceFile = tempFile;
      }

      final fileName = entry.originalTitle ?? sourceFile.uri.pathSegments.last;
      final isVideo = _isVideo(sourceFile.path);

      try {
        if (isVideo) {
          await PhotoManager.editor.saveVideo(
            sourceFile,
            title: fileName,
            relativePath: entry.relativePath,
          );
        } else {
          await PhotoManager.editor.saveImageWithPath(
            sourceFile.path,
            title: fileName,
            relativePath: entry.relativePath,
          );
        }
      } finally {
        // Clean up temp file if we created one.
        if (tempFile != null && tempFile.existsSync()) {
          await tempFile.delete();
        }
      }

      // Delete the original vault file.
      if (File(vaultPath).existsSync()) await File(vaultPath).delete();
    } catch (_) {
      // Ignore restore errors silently
    }
  }

  bool _isVideo(String path) {
    // For .vault files, check the embedded real extension.
    final check = path.endsWith('.vault') ? _originalExt(path) : path;
    final ext = check.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.3gp');
  }

  // ── delete permanently ───────────────────────────────────────────────────

  Future<void> deletePermanently(String vaultPath) async {
    try {
      await File(vaultPath).delete();
    } catch (_) {}
  }
}
