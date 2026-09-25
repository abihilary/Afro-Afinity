import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../core/widgets/pressable.dart';
import '../../models/feed.dart';
import '../../models/feed_store.dart';
import '../../models/user.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePostSheet(),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _captionController = TextEditingController();
  final _cityController = TextEditingController(text: 'Stuttgart');
  final _countryController = TextEditingController(text: 'Germany');
  final ImagePicker _picker = ImagePicker();

  String? _selectedImagePath;
  String _visibility = 'public'; // 'public' | 'private'
  bool _isPublishing = false;

  @override
  void dispose() {
    _captionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  void _publish() {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo or caption to share.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    final user = AppUser.instance;
    final photoUrl = _selectedImagePath ??
        'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=1080&q=90';

    final newPost = FeedPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      authorId: 'user_${user.name.toLowerCase()}',
      authorName: user.name,
      authorAvatar: user.photos.isNotEmpty
          ? user.photos.first
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=90',
      isAuthorVerified: user.isVerified,
      type: 'photo',
      caption: caption.isEmpty ? 'Sharing a beautiful moment ✨' : caption,
      media: [
        FeedMedia(
          id: 'media_${DateTime.now().millisecondsSinceEpoch}',
          type: 'image',
          url: photoUrl,
          thumbnailUrl: photoUrl,
        ),
      ],
      location: FeedLocation(
        city: _cityController.text.trim().isEmpty
            ? 'Stuttgart'
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? 'Germany'
            : _countryController.text.trim(),
      ),
      visibility: _visibility,
      commentsEnabled: true,
      likeCount: 1,
      commentCount: 0,
      shareCount: 0,
      createdAt: DateTime.now(),
    );

    FeedStore.instance.addPost(newPost);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feed post published! ✨'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ThemeColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.mutedText(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Feed Post',
                        style: TextStyle(
                          color: ThemeColors.text(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ThemeColors.surfaceAlt(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: ThemeColors.text(context),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Photo Selector Container
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ThemeColors.surface(context),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: _selectedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    color: AppColors.gold,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tap to choose photo',
                                  style: TextStyle(
                                    color: ThemeColors.text(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PNG, JPG up to 10MB',
                                  style: TextStyle(
                                    color: ThemeColors.mutedText(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Caption Input
                  Text(
                    'CAPTION',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ThemeColors.surface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ThemeColors.border(context)),
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 3,
                      style: TextStyle(color: ThemeColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'Share what’s on your mind...',
                        hintStyle: TextStyle(
                          color: ThemeColors.mutedText(context),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location Inputs Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CITY',
                              style: TextStyle(
                                color: ThemeColors.mutedText(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: ThemeColors.surface(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: ThemeColors.border(context)),
                              ),
                              child: TextField(
                                controller: _cityController,
                                style: TextStyle(
                                    color: ThemeColors.text(context)),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Stuttgart',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COUNTRY',
                              style: TextStyle(
                                color: ThemeColors.mutedText(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: ThemeColors.surface(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: ThemeColors.border(context)),
                              ),
                              child: TextField(
                                controller: _countryController,
                                style: TextStyle(
                                    color: ThemeColors.text(context)),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Germany',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Visibility Toggle (Public / Private)
                  Text(
                    'VISIBILITY',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          onTap: () => setState(() => _visibility = 'public'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _visibility == 'public'
                                  ? AppColors.pink
                                  : ThemeColors.surface(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _visibility == 'public'
                                    ? AppColors.pink
                                    : ThemeColors.border(context),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.public_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Public 🌐',
                                  style: TextStyle(
                                    color: _visibility == 'public'
                                        ? Colors.white
                                        : ThemeColors.text(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PressableScale(
                          onTap: () => setState(() => _visibility = 'private'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _visibility == 'private'
                                  ? AppColors.purple
                                  : ThemeColors.surface(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _visibility == 'private'
                                    ? AppColors.purple
                                    : ThemeColors.border(context),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Private 🔒',
                                  style: TextStyle(
                                    color: _visibility == 'private'
                                        ? Colors.white
                                        : ThemeColors.text(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Publish Button
                  PressableScale(
                    onTap: _isPublishing ? null : _publish,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.pink, AppColors.purple],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isPublishing ? 'Publishing...' : 'Publish Feed Post ✨',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
