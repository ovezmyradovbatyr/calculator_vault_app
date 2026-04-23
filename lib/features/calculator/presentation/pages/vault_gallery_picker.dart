import 'dart:typed_data';
import 'package:calculator_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

const _orange = Color(0xFFFF9F0A);

/// Standalone gallery picker built on photo_manager.
/// Returns the selected [AssetEntity] list. Never returns null — cancelling
/// gives an empty list.
Future<List<AssetEntity>> showVaultGalleryPicker(BuildContext context) async {
  final result = await Navigator.of(context).push<List<AssetEntity>>(
    MaterialPageRoute(builder: (_) => const _VaultGalleryPickerPage()),
  );
  return result ?? [];
}

class _VaultGalleryPickerPage extends StatefulWidget {
  const _VaultGalleryPickerPage();

  @override
  State<_VaultGalleryPickerPage> createState() =>
      _VaultGalleryPickerPageState();
}

class _VaultGalleryPickerPageState extends State<_VaultGalleryPickerPage> {
  List<AssetEntity> _assets = [];
  final Set<AssetEntity> _selected = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth && !perm.hasAccess) {
      setState(() {
        _error = 'Gallery permission denied.';
        _loading = false;
      });
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final album = albums.first;
    final count = await album.assetCountAsync;
    if (count == 0) {
      setState(() {
        _loading = false;
      });
      return;
    }

    // Load up to 1000 most recent assets.
    final end = count < 1000 ? count : 1000;
    final assets = await album.getAssetListRange(start: 0, end: end);
    setState(() {
      _assets = assets;
      _loading = false;
    });
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      if (_selected.contains(asset)) {
        _selected.remove(asset);
      } else {
        _selected.add(asset);
      }
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          _selected.isEmpty
              ? AppLocalizations.instance.t('select')
              : '${_selected.length} ${AppLocalizations.instance.t('selected')}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, <AssetEntity>[]),
        ),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _confirm,
              child: Text(
                AppLocalizations.instance.t('add'),
                style: const TextStyle(
                  color: _orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white54)),
      );
    }
    if (_assets.isEmpty) {
      return const Center(
        child: Text(
          'No photos found.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _assets.length,
      itemBuilder: (_, i) {
        final asset = _assets[i];
        final sel = _selected.contains(asset);
        return GestureDetector(
          onTap: () => _toggle(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _AssetThumbnail(asset: asset),
              if (asset.type == AssetType.video)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatDuration(asset.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          shadows: [Shadow(blurRadius: 2)],
                        ),
                      ),
                    ],
                  ),
                ),
              // dim overlay when selected
              if (sel) Container(color: _orange.withAlpha(80)),
              // selection circle
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sel ? _orange : Colors.transparent,
                    border: Border.all(
                      color: sel ? _orange : Colors.white70,
                      width: 2,
                    ),
                  ),
                  child: sel
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  const _AssetThumbnail({required this.asset});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
    if (mounted && data != null) {
      setState(() => _bytes = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return Container(
        color: const Color(0xFF1C1C1E),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white24,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    return Image.memory(_bytes!, fit: BoxFit.cover);
  }
}
