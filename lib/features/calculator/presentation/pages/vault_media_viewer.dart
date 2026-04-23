import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VaultMediaViewer extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const VaultMediaViewer({
    super.key,
    required this.paths,
    required this.initialIndex,
  });

  @override
  State<VaultMediaViewer> createState() => _VaultMediaViewerState();
}

class _VaultMediaViewerState extends State<VaultMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  bool _isVideo(String path) {
    final ext = _realExt(path);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.paths.length}',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final path = widget.paths[i];
          return _isVideo(path)
              ? _FullScreenVideo(key: ValueKey(path), path: path)
              : _FullScreenImage(key: ValueKey(path), path: path);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenImage extends StatefulWidget {
  final String path;
  const _FullScreenImage({super.key, required this.path});

  @override
  State<_FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<_FullScreenImage>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _bytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    final bytes = await File(widget.path).readAsBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_bytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF9F0A)),
      );
    }
    return InteractiveViewer(
      child: Center(
        child: Image.memory(
          _bytes!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.broken_image, color: Colors.white30, size: 64),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenVideo extends StatefulWidget {
  final String path;
  const _FullScreenVideo({super.key, required this.path});

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _controller.play();
        }
      })
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF9F0A)),
      );
    }
    return GestureDetector(
      onTap: () => setState(
        () => _controller.value.isPlaying
            ? _controller.pause()
            : _controller.play(),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video thumbnail (used in grid)
// ─────────────────────────────────────────────────────────────────────────────

class VaultVideoThumbnail extends StatefulWidget {
  final String path;
  const VaultVideoThumbnail({super.key, required this.path});

  @override
  State<VaultVideoThumbnail> createState() => _VaultVideoThumbnailState();
}

class _VaultVideoThumbnailState extends State<VaultVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && _controller != null) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }
    return Container(
      color: const Color(0xFF2C2C2E),
      child: const Center(
        child: Icon(Icons.videocam, color: Colors.white30, size: 32),
      ),
    );
  }
}
