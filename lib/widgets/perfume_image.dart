import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controller/utils/app_colors.dart';

class PerfumeImage extends StatelessWidget {
  final String? path;
  /// Square side when [layoutWidth] / [layoutHeight] are not both set.
  final double size;
  /// When both set, image fills this rectangle (full-width banner, etc.).
  final double? layoutWidth;
  final double? layoutHeight;
  final BorderRadius borderRadius;

  const PerfumeImage({
    super.key,
    required this.path,
    required this.size,
    this.layoutWidth,
    this.layoutHeight,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  }) : assert(
          size > 0 || (layoutWidth != null && layoutHeight != null),
          'Provide a positive size, or both layoutWidth and layoutHeight.',
        );

  double get _w =>
      (layoutWidth != null && layoutHeight != null) ? layoutWidth! : size;
  double get _h =>
      (layoutWidth != null && layoutHeight != null) ? layoutHeight! : size;

  double get _iconEmblem =>
      (_w < _h ? _w : _h) * 0.38;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (path == null || path!.isEmpty) {
      child = Center(
        child: Icon(
          Icons.local_florist_rounded,
          color: AppColors.textTertiary,
          size: _iconEmblem,
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
          size: _iconEmblem,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: _w,
        height: _h,
        color: AppColors.surfaceMuted,
        child: child,
      ),
    );
  }
}

