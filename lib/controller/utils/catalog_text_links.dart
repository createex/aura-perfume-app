import 'package:linkify/linkify.dart';

/// Finds the first http(s) URL in free-form catalog text (e.g. NOTAS DEL CATÁLOGO).
String? firstHttpUrlInText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  for (final e in linkify(
    raw,
    options: const LinkifyOptions(
      humanize: false,
      looseUrl: true,
      defaultToHttps: true,
      excludeLastPeriod: true,
    ),
    linkifiers: const [UrlLinkifier()],
  )) {
    if (e is UrlElement) {
      final u = e.url.trim();
      if (u.isNotEmpty) return u;
    }
  }
  return null;
}
