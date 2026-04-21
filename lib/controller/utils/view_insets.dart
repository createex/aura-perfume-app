import 'package:flutter/material.dart';

/// System / gesture insets not covered by [SafeArea] alone on some roots.
class ViewInsets {
  ViewInsets._();

  /// Bottom inset from the OS (e.g. Android 3-button or gesture navigation bar).
  static double bottomOverlap(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;
}
