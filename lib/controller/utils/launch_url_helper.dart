import 'package:url_launcher/url_launcher.dart';

import 'app_log.dart';

/// Opens http(s) links in the external browser. Avoids [canLaunchUrl], which
/// often returns false on Android even when [launchUrl] works.
class LaunchUrlHelper {
  LaunchUrlHelper._();

  static Uri? normalizeHttpUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    var s = t;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(s)) {
      s = 'https://$s';
    }
    return Uri.tryParse(s);
  }

  static Future<bool> openInExternalBrowser(String raw) async {
    final u = normalizeHttpUrl(raw);
    if (u == null || (u.scheme != 'http' && u.scheme != 'https')) {
      AppLog.warning('LaunchUrl: invalid or non-http(s) URL', raw);
      return false;
    }
    try {
      final ok = await launchUrl(
        u,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        AppLog.warning('LaunchUrl: launchUrl returned false', u.toString());
      } else {
        AppLog.action('Launched external browser', {'uri': u.toString()});
      }
      return ok;
    } catch (e, _) {
      AppLog.warning(
        'LaunchUrl: exception',
        {'error': e.toString(), 'uri': u.toString()},
      );
      return false;
    }
  }
}
