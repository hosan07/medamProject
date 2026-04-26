import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/community_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';

class PostWriteScreen extends ConsumerStatefulWidget {
  const PostWriteScreen({super.key});

  @override
  ConsumerState<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends ConsumerState<PostWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  String _category = '음식평가';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('글쓰기')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 720 : 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: '카테고리'),
                    items: communityCategories
                        .where((category) => category != '전체')
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      hintText: '궁금한 점이나 기록 제목을 적어주세요',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    minLines: 8,
                    maxLines: 12,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: '내용',
                      hintText: '서로에게 도움이 되는 이야기를 나눠주세요',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ImagePickerRow(
                    images: _images,
                    onPick: _pickImages,
                    onRemove: (index) =>
                        setState(() => _images.removeAt(index)),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('등록하기'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(limit: 5);
    if (images.isEmpty) {
      return;
    }
    setState(() {
      _images.addAll(images);
      if (_images.length > 5) {
        _images.removeRange(5, _images.length);
      }
    });
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (user == null || title.isEmpty || content.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = await ref
          .read(firebaseFirestoreProvider)
          .doc('users/${user.uid}')
          .get();
      final data = profile.data();
      final postId = await ref
          .read(communityRepositoryProvider)
          .createPost(
            uid: user.uid,
            nickname:
                data?['nickname'] as String? ??
                user.displayName ??
                user.email ??
                '미담러',
            profileImage: data?['profileImage'] as String?,
            category: _category,
            title: title,
            content: content,
            images: _images,
          );
      if (mounted) {
        context.go('/community/posts/$postId');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _ImagePickerRow extends StatelessWidget {
  const _ImagePickerRow({
    required this.images,
    required this.onPick,
    required this.onRemove,
  });

  final List<XFile> images;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (index == 0) {
            return OutlinedButton.icon(
              onPressed: images.length >= 5 ? null : onPick,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: Text('${images.length}/5'),
            );
          }
          final image = images[index - 1];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(image.path),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => Container(
                    width: 88,
                    height: 88,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: const Icon(Icons.image_rounded),
                  ),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: IconButton.filled(
                  onPressed: () => onRemove(index - 1),
                  iconSize: 16,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: images.length + 1,
      ),
    );
  }
}
