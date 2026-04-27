import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/food_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/camera_provider.dart';

final bodyPhotoAlbumProvider = StreamProvider<List<BodyPhotoEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(foodRepositoryProvider).watchBodyPhotos(user.uid);
});

class BodyCameraScreen extends ConsumerStatefulWidget {
  const BodyCameraScreen({this.autoCapture = true, super.key});

  final bool autoCapture;

  @override
  ConsumerState<BodyCameraScreen> createState() => _BodyCameraScreenState();
}

class _BodyCameraScreenState extends ConsumerState<BodyCameraScreen> {
  File? _preview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
    }
  }

  Future<void> _capture() async {
    final file = await ref.read(cameraCaptureProvider).capturePhoto();
    if (!mounted) {
      return;
    }
    setState(() => _preview = file);
  }

  Future<void> _save() async {
    final file = _preview;
    final user = ref.read(currentUserProvider);
    if (file == null || user == null) {
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(foodRepositoryProvider);
    final imageUrl = await repository.uploadImage(
      uid: user.uid,
      file: file,
      folder: 'body_photos',
    );
    await repository.saveBodyPhotoToPublicPath(
      uid: user.uid,
      imageUrl: imageUrl,
    );
    await repository.saveBodyPhoto(uid: user.uid, imageUrl: imageUrl);
    await ImageGallerySaver.saveFile(file.path);
    ref.invalidate(bodyPhotoAlbumProvider);

    if (!mounted) {
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('눈바디 사진을 저장했어요.')));
    setState(() {
      _saving = false;
      _preview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final album = ref.watch(bodyPhotoAlbumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('눈바디 기록')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final preview = _PreviewPanel(
                    file: _preview,
                    saving: _saving,
                    onCapture: _capture,
                    onSave: _save,
                  );
                  final grid = _BodyAlbumGrid(album: album);

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: preview),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: grid),
                          ],
                        )
                      : ListView(
                          children: [preview, const SizedBox(height: 18), grid],
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.file,
    required this.saving,
    required this.onCapture,
    required this.onSave,
  });

  final File? file;
  final bool saving;
  final VoidCallback onCapture;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: file == null
                  ? Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: const Center(child: Text('촬영할 사진을 준비해 주세요.')),
                    )
                  : Image.file(file!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : onCapture,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('다시 찍기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: file == null || saving ? null : onSave,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(saving ? '저장 중...' : '저장하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyAlbumGrid extends StatelessWidget {
  const _BodyAlbumGrid({required this.album});

  final AsyncValue<List<BodyPhotoEntry>> album;

  @override
  Widget build(BuildContext context) {
    return album.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyAlbum();
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (context, index) => _AlbumTile(entry: items[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _EmptyAlbum(),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.entry});

  final BodyPhotoEntry entry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(entry.imageUrl, fit: BoxFit.cover),
          Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  DateFormat('M.d').format(entry.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlbum extends StatelessWidget {
  const _EmptyAlbum();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: Text('저장된 눈바디 사진이 없어요.')),
    );
  }
}
