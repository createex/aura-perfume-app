import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controller/utils/app_colors.dart';

class PerfumeImage extends StatelessWidget {
  final String? path;
  final double size;
  final BorderRadius borderRadius;

  const PerfumeImage({
    super.key,
    required this.path,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (path == null || path!.isEmpty) {
      child = Center(
        child: Icon(
          Icons.local_florist_rounded,
          color: AppColors.textTertiary,
          size: size * 0.38,
        ),
      );
    } else if (path!.startsWith('assets/') && path!.endsWith('.svg')) {
      child = SvgPicture.asset(path!, fit: BoxFit.cover);
    } else if (path!.startsWith('assets/')) {
      child = Image.asset(path!, fit: BoxFit.cover);
    } else if (File(path!).existsSync()) {
      child = Image.file(File(path!), fit: BoxFit.cover);
    } else {
      child = Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textTertiary,
          size: size * 0.38,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceMuted,
        child: child,
      ),
    );
  }
}

