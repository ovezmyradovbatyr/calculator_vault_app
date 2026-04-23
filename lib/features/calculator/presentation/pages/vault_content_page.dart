import 'package:flutter/material.dart';
import '../widgets/vault_add_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import 'vault_gallery_picker.dart';
import 'vault_media_viewer.dart';
import 'vault_pin_screen.dart';
import 'vault_selection_bar.dart';
import 'vault_service.dart'; // VaultEntry, VaultService
import 'vault_thumbnail.dart';

const _orange = Color(0xFFFF9F0A);

class VaultContentPage extends StatefulWidget {
  const VaultContentPage({super.key});

  @override
  State<VaultContentPage> createState() => _VaultContentPageState();
}

class _VaultContentPageState extends State<VaultContentPage>
    with SingleTickerProviderStateMixin {
  final _service = VaultService();

  List<String> _paths = [];
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _selectionMode = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _load();
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkManageMediaPermission();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final paths = await _service.loadMedia();
    if (mounted) setState(() => _paths = paths);
  }

  Future<void> _save() => _service.saveMedia(_paths);

  /// Запрашивает MANAGE_MEDIA один раз при первом открытии сейфа (Android 12+).
  /// С этим разрешением удаление из галереи происходит без системного диалога.
  Future<void> _checkManageMediaPermission() async {
    if (!mounted) return;
    if (await _service.hasHandledManageMedia()) return;
    final granted = await _service.isManageMediaGranted();
    if (!granted && mounted) {
      final l = AppLocalizations.instance;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(
            l.t('mediaPermissionTitle'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            l.t('mediaPermissionBody'),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l.t('later'),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.t('allow'), style: const TextStyle(color: _orange)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _service.requestManageMediaPermission();
      }
    }
    await _service.setHandledManageMedia();
  }

  // ── add ────────────────────────────────────────────────────────────────

  /// Gallery: use the custom photo_manager picker so we have AssetEntity
  /// directly → reliable deletion from MediaStore.
  Future<void> _addFromGallery() async {
    if (!mounted) return;
    final assets = await showVaultGalleryPicker(context);
    if (assets.isEmpty || !mounted) return;
    final entries = await _service.addAssetsToVault(assets);
    if (entries.isNotEmpty && mounted) {
      setState(() => _paths.addAll(entries.map((e) => e.path)));
      await _save();
    }
  }

  /// Camera: use image_picker (no MediaStore entry to delete).
  Future<void> _addFromCamera({required bool isVideo}) async {
    final entry = await _service.pickFromCamera(isVideo: isVideo);
    if (entry != null && mounted) {
      setState(() => _paths.add(entry.path));
      await _save();
    }
  }

  // ── selection

  void _enterSelection(int index) => setState(() {
    _selectionMode = true;
    _selected.add(index);
  });

  void _exitSelection() => setState(() {
    _selectionMode = false;
    _selected.clear();
  });

  void _toggleSelect(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == _paths.length) {
        _selected.clear();
        _selectionMode = false;
      } else {
        _selected.addAll(List.generate(_paths.length, (i) => i));
      }
    });
  }

  // ── restore / delete selected ─────────────────────────────────────────

  Future<void> _handleAction({required bool restore}) async {
    final indices = _selected.toList()..sort((a, b) => b.compareTo(a));
    final count = indices.length;

    if (restore) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(
            AppLocalizations.instance.t('restoreToGallery'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            '$count ${AppLocalizations.instance.t('restoreConfirmBody')}',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLocalizations.instance.t('cancel'),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.instance.t('restoreToGallery'),
                style: TextStyle(color: _orange),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    for (final i in indices) {
      final p = _paths[i];
      restore
          ? await _service.restoreToGallery(p)
          : await _service.deletePermanently(p);
      _paths.removeAt(i);
    }

    await _save();
    setState(() {
      _selected.clear();
      _selectionMode = false;
    });
  }

  // ── bottom sheet ───────────────────────────────────────────────────────

  void _showLanguageDialog(BuildContext context) {
    final l = AppLocalizations.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.t('language'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _langSheetTile(ctx, 'en', l.t('english'), '🇺🇸'),
              _langSheetTile(ctx, 'ru', l.t('russian'), '🇷🇺'),
              _langSheetTile(ctx, 'tk', l.t('turkmen'), '🇹🇲'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langSheetTile(
    BuildContext sheetCtx,
    String code,
    String label,
    String flag,
  ) {
    final current = AppLocalizations.instance.locale == code;
    return GestureDetector(
      onTap: () async {
        await AppLocalizations.instance.setLocale(code);
        if (mounted) {
          Navigator.pop(sheetCtx);
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: current ? _orange.withOpacity(0.15) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(14),
          border: current
              ? Border.all(color: _orange, width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: current ? _orange : Colors.white,
                fontSize: 16,
                fontWeight: current ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (current)
              const Icon(Icons.check_circle, color: _orange, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAddSheet() {
    showVaultAddSheet(
      context,
      onAddFromGallery: _addFromGallery,
      onAddFromCamera: _addFromCamera,
    );
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: _buildAppBar(),
        body: _paths.isEmpty ? _buildEmpty() : _buildGrid(),
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton(
                backgroundColor: _orange,
                onPressed: _showAddSheet,
                child: const Icon(Icons.add, color: Colors.white),
              ),
      ),
    );
  }

  AppBar _buildAppBar() {
    if (_selectionMode) {
      return AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _exitSelection,
        ),
        title: Text(
          '${_selected.length} ${AppLocalizations.instance.t('selected')}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _selected.length == _paths.length
                  ? Icons.deselect
                  : Icons.select_all,
              color: Colors.white,
            ),
            onPressed: _selectAll,
          ),
        ],
      );
    }
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      leading: IconButton(
        icon: const Icon(Icons.lock, color: _orange),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.instance.t('secretVault'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.language, color: _orange),
          tooltip: AppLocalizations.instance.t('language'),
          onPressed: () => _showLanguageDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.password, color: _orange),
          tooltip: AppLocalizations.instance.t('changePin'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VaultPinScreen(mode: VaultPinMode.change),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Stack(
      children: [
        GridView.builder(
          padding: EdgeInsets.only(
            bottom: _selectionMode ? 80 : 4,
            top: 4,
            left: 4,
            right: 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _paths.length,
          itemBuilder: (_, i) => VaultThumbnail(
            index: i,
            path: _paths[i],
            selectionMode: _selectionMode,
            selected: _selected.contains(i),
            onLongPress: () => _enterSelection(i),
            onTap: () {
              if (_selectionMode) {
                _toggleSelect(i);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VaultMediaViewer(paths: _paths, initialIndex: i),
                  ),
                );
              }
            },
          ),
        ),
        if (_selectionMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VaultSelectionBar(
              canAct: _selected.isNotEmpty,
              onDelete: () => _handleAction(restore: false),
              onRestore: () => _handleAction(restore: true),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: _orange, size: 64),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.instance.t('vaultIsEmpty'),
            style: const TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.instance.t('tapToAdd'),
            style: const TextStyle(color: Colors.white30, fontSize: 14),
          ),
          const SizedBox(height: 24),
          // ElevatedButton.icon(
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: _orange,
          //     foregroundColor: Colors.white,
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(24),
          //     ),
          //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          //   ),
          //   icon: const Icon(Icons.add),
          //   label: const Text('Add Media'),
          //   onPressed: _showAddSheet,
          // ),
        ],
      ),
    );
  }
}
