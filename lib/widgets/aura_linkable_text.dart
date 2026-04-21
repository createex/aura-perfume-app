import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';

import '../controller/utils/app_colors.dart';
import '../controller/utils/launch_url_helper.dart';

/// Plain text with detected http(s) URLs as tappable, underlined spans.
class AuraLinkableText extends StatefulWidget {
  const AuraLinkableText({
    super.key,
    required this.text,
    required this.style,
    this.linkStyle,
    this.strutStyle,
  });

  final String text;
  final TextStyle style;
  final TextStyle? linkStyle;
  final StrutStyle? strutStyle;

  @override
  State<AuraLinkableText> createState() => _AuraLinkableTextState();
}

class _AuraLinkableTextState extends State<AuraLinkableText> {
  final List<TapGestureRecognizer> _recognizers = [];
  List<InlineSpan> _spans = const [];

  static const _linkifyOptions = LinkifyOptions(
    humanize: false,
    looseUrl: true,
    defaultToHttps: true,
    excludeLastPeriod: true,
  );

  @override
  void initState() {
    super.initState();
    _rebuildSpans();
  }

  @override
  void didUpdateWidget(covariant AuraLinkableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _rebuildSpans();
      setState(() {});
    }
  }

  void _rebuildSpans() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final out = <InlineSpan>[];
    final linkStyle = widget.linkStyle ??
        widget.style.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
          fontWeight: FontWeight.w600,
        );

    for (final e in linkify(
      widget.text,
      options: _linkifyOptions,
      linkifiers: const [UrlLinkifier()],
    )) {
      if (e is UrlElement) {
        final href = e.url.trim();
        final r = TapGestureRecognizer()
          ..onTap = () {
            LaunchUrlHelper.openInExternalBrowser(href);
          };
        _recognizers.add(r);
        out.add(
          TextSpan(
            text: e.text,
            style: linkStyle,
            recognizer: r,
            mouseCursor: SystemMouseCursors.click,
          ),
        );
      } else {
        out.add(TextSpan(text: e.text, style: widget.style));
      }
    }

    _spans = out;
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SelectableText.rich keeps link taps reliable (SelectionArea can steal gestures).
    return SelectableText.rich(
      TextSpan(children: _spans),
      style: widget.style,
      strutStyle: widget.strutStyle,
    );
  }
}
