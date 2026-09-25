import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class SafeImage extends StatelessWidget {
  const SafeImage({
    super.key,
    required this.urlOrPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.person_rounded,
  });

  final String? urlOrPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildImage() {
    if (urlOrPath == null || urlOrPath!.isEmpty) {
      return _placeholder();
    }

    final path = urlOrPath!;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.darkSurface2,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.darkSurface2,
      child: Center(
        child: Icon(
          placeholderIcon,
          color: Colors.white24,
          size: (width != null && width! < 60) ? 22 : 36,
        ),
      ),
    );
  }
}
