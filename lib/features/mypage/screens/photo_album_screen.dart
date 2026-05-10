import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../core/widgets/medam_confirm_dialog.dart';
import '../../../data/repositories/photo_repository.dart';
import '../../auth/providers/auth_provider.dart';

class PhotoAlbumScreen extends ConsumerStatefulWidget {
  const PhotoAlbumScreen({super.key});

  @override
  ConsumerState<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends ConsumerState<PhotoAlbumScreen> {
  static const _noticeKey = 'photo_album_notice_shown';

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _type = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNoticeIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('앨범')),
      body: user == null
          ? const Center(child: Text('로그인이 필요해요'))
          : Column(
              children: [
                _FilterChips(
                  selectedType: _type,
                  onChanged: (value) => setState(() => _type = value),
                ),
                _MonthNavigator(
                  month: _month,
                  onPrevious: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  onNext: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<PhotoAlbumItem>>(
                    stream: ref
                        .watch(photoRepositoryProvider)
                        .watchMonthPhotos(
                          uid: user.uid,
                          month: _month,
                          type: _type,
                        ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data ?? const <PhotoAlbumItem>[];
                      if (items.isEmpty) {
                        return _EmptyAlbum(
                          onCameraTap: () => context.go('/camera'),
                        );
                      }
                      return _PhotoGrid(uid: user.uid, items: items);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showNoticeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_noticeKey) ?? false) {
      return;
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내 사진은 내 폰에 저장돼요'),
        content: const Text(
          '· 사진은 기본적으로 내 기기에만 저장돼요\n'
          '· 갤러리에서 지우면 기록도 사라져요\n'
          '· 백업 기능으로 서버에 안전하게 저장할 수 있어요',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인했어요'),
          ),
        ],
      ),
    );
    await prefs.setBool(_noticeKey, true);
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedType, required this.onChanged});

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = {'all': '전체', 'body': '눈바디', 'food': '음식'};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: Row(
        children: [
          for (final entry in filters.entries) ...[
            ChoiceChip(
              label: Text(entry.value),
              selected: selectedType == entry.key,
              onSelected: (_) => onChanged(entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('yyyy년 M월', 'ko_KR').format(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: '이전 달',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          IconButton(
            tooltip: '다음 달',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlbum extends StatelessWidget {
  const _EmptyAlbum({required this.onCameraTap});

  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('이 달에 기록된 사진이 없어요'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCameraTap,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('카메라 열기'),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid({required this.uid, required this.items});

  final String uid;
  final List<PhotoAlbumItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final fileExists =
            item.localPath.isNotEmpty && File(item.localPath).existsSync();
        if (!fileExists && !item.isBackedUp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(photoRepositoryProvider)
                .deletePhotoDocument(uid: uid, photoId: item.id);
          });
        }

        return InkWell(
          onTap: fileExists || item.remoteUrl.isNotEmpty
              ? () => _showPhotoViewer(context, uid, index)
              : null,
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoImage(item: item, fileExists: fileExists),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Badge(label: Text(item.type == 'food' ? '음식' : '눈바디')),
                ),
                if (item.isBackedUp)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_done_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                if (item.isVideo)
                  Center(
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 40,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPhotoViewer(BuildContext context, String uid, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _PhotoViewer(uid: uid, items: items, initialIndex: initialIndex),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.item, required this.fileExists});

  final PhotoAlbumItem item;
  final bool fileExists;

  @override
  Widget build(BuildContext context) {
    if (fileExists) {
      if (item.isVideo) {
        return _VideoThumbnail(path: item.localPath);
      }
      return Image.file(File(item.localPath), fit: BoxFit.cover);
    }
    if (item.remoteUrl.isNotEmpty) {
      if (item.isVideo) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: Icon(Icons.play_circle_filled_rounded, color: Colors.white),
          ),
        );
      }
      return CachedNetworkImage(
        imageUrl: item.remoteUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const _MissingPhoto(),
      );
    }
    return const _MissingPhoto();
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Text('갤러리에서 삭제됨')),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: VideoThumbnail.thumbnailFile(
        video: path,
        imageFormat: ImageFormat.JPEG,
        quality: 70,
      ),
      builder: (context, snapshot) {
        final thumbPath = snapshot.data;
        if (thumbPath != null && File(thumbPath).existsSync()) {
          return Image.file(File(thumbPath), fit: BoxFit.cover);
        }
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: Icon(Icons.videocam_rounded, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _PhotoViewer extends ConsumerStatefulWidget {
  const _PhotoViewer({
    required this.uid,
    required this.items,
    required this.initialIndex,
  });

  final String uid;
  final List<PhotoAlbumItem> items;
  final int initialIndex;

  @override
  ConsumerState<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<_PhotoViewer> {
  late final PageController _pageController;
  late int _index;
  bool _showOverlay = true;
  final Set<String> _backedUpIds = {};
  String? _uploadingId;
  double _backupProgress = 0;

  PhotoAlbumItem get _current => widget.items[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final backedUp = current.isBackedUp || _backedUpIds.contains(current.id);
    final isUploading = _uploadingId == current.id;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return _ViewerPage(item: widget.items[index]);
              },
            ),
            if (_showOverlay)
              _TopOverlay(
                item: current,
                isBackedUp: backedUp,
                isUploading: isUploading,
                uploadProgress: _backupProgress,
                onClose: () => Navigator.of(context).pop(),
              ),
            if (_showOverlay)
              _BottomOverlay(
                onSave: () => _saveToGallery(context, current),
                onShare: () => _share(context, current),
                onBackup: () => _backup(context, current),
                onDelete: () => _delete(context, current),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery(BuildContext context, PhotoAlbumItem item) async {
    if (item.localPath.isNotEmpty && File(item.localPath).existsSync()) {
      _showSnack(context, '이미 저장된 사진이에요');
      return;
    }
    if (item.remoteUrl.isEmpty) {
      _showSnack(context, '저장할 원본 파일이 없어요');
      return;
    }

    try {
      final tempFile = File(
        '${Directory.systemTemp.path}/medam_${item.id}.jpg',
      );
      await Dio().download(item.remoteUrl, tempFile.path);
      await ImageGallerySaver.saveFile(tempFile.path);
      if (!context.mounted) {
        return;
      }
      _showSnack(context, '갤러리에 저장했어요');
    } on Object {
      if (!context.mounted) {
        return;
      }
      _showSnack(context, '저장에 실패했어요. 다시 시도해주세요');
    }
  }

  Future<void> _share(BuildContext context, PhotoAlbumItem item) async {
    if (item.localPath.isEmpty || !File(item.localPath).existsSync()) {
      _showSnack(context, '공유할 원본 파일이 없어요');
      return;
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(item.localPath)]));
  }

  Future<void> _backup(BuildContext context, PhotoAlbumItem item) async {
    if (item.isBackedUp || _backedUpIds.contains(item.id)) {
      _showSnack(context, '이미 백업됐어요 ✓');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => MedamConfirmDialog(
        title: '서버에 백업할까요?',
        content: '백업된 사진은 기기를 바꿔도\n미담 앱에서 볼 수 있어요',
        confirmText: '백업하기',
        onConfirm: () async {
          try {
            if (mounted) {
              setState(() {
                _uploadingId = item.id;
                _backupProgress = 0;
              });
            }
            await ref
                .read(photoRepositoryProvider)
                .backupPhoto(
                  uid: widget.uid,
                  item: item,
                  onProgress: (progress) {
                    if (!mounted) {
                      return;
                    }
                    setState(() => _backupProgress = progress.clamp(0, 1));
                  },
                );
            if (mounted) {
              setState(() {
                _backedUpIds.add(item.id);
                _uploadingId = null;
                _backupProgress = 1;
              });
            }
            if (context.mounted) {
              _showSnack(context, '백업 완료!');
            }
          } on Object {
            if (mounted) {
              setState(() {
                _uploadingId = null;
                _backupProgress = 0;
              });
            }
            if (context.mounted) {
              _showSnack(context, '백업에 실패했어요. 다시 시도해주세요');
            }
          }
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, PhotoAlbumItem item) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => MedamConfirmDialog(
        title: '기록을 삭제할까요?',
        content: '앱 기록만 삭제되고\n갤러리 원본은 유지돼요.\n백업된 경우 서버 파일도 함께 삭제돼요.',
        confirmText: '삭제',
        confirmIsDestructive: true,
        onConfirm: () async {
          await ref
              .read(photoRepositoryProvider)
              .deletePhoto(uid: widget.uid, item: item);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({required this.item});

  final PhotoAlbumItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return _VideoPlayerPage(item: item);
    }
    final fileExists =
        item.localPath.isNotEmpty && File(item.localPath).existsSync();
    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: fileExists
            ? Image.file(File(item.localPath), fit: BoxFit.contain)
            : CachedNetworkImage(
                imageUrl: item.remoteUrl,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  const _VideoPlayerPage({required this.item});

  final PhotoAlbumItem item;

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final localFile = File(widget.item.localPath);
    final controller = localFile.existsSync()
        ? VideoPlayerController.file(localFile)
        : VideoPlayerController.networkUrl(Uri.parse(widget.item.remoteUrl));
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();
    if (mounted) {
      setState(() => _controller = controller);
    } else {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
        setState(() {});
      },
      child: Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: Color(0xFF4CAF82)),
            ),
            if (!controller.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 72,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.item,
    required this.isBackedUp,
    required this.isUploading,
    required this.uploadProgress,
    required this.onClose,
  });

  final PhotoAlbumItem item;
  final bool isBackedUp;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title =
        '${DateFormat('yyyy. M. d', 'ko_KR').format(item.date)} / ${item.categoryLabel}';
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          8,
          MediaQuery.paddingOf(context).top + 8,
          8,
          28,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '닫기',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isBackedUp) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            if (isUploading) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: LinearProgressIndicator(
                  value: uploadProgress == 0 ? null : uploadProgress,
                  color: const Color(0xFF4CAF82),
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({
    required this.onSave,
    required this.onShare,
    required this.onBackup,
    required this.onDelete,
  });

  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onBackup;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          32,
          12,
          MediaQuery.paddingOf(context).bottom + 14,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            _ViewerAction(
              icon: Icons.save_alt_rounded,
              label: '저장',
              onTap: onSave,
            ),
            _ViewerAction(
              icon: Icons.ios_share_rounded,
              label: '공유',
              onTap: onShare,
            ),
            _ViewerAction(
              icon: Icons.cloud_upload_rounded,
              label: '백업',
              onTap: onBackup,
            ),
            _ViewerAction(
              icon: Icons.delete_outline_rounded,
              label: '삭제',
              danger: true,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF6B6B) : Colors.white;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
