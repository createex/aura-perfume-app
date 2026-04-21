import 'package:flutter/material.dart';

import 'app_log.dart';

/// Logs Flutter navigator stack changes (complements GetX [routingCallback]).
class AuraNavigatorObserver extends NavigatorObserver {
  String _label(Route<dynamic>? route) {
    if (route == null) return '(null)';
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    final args = route.settings.arguments;
    if (args != null) return '${route.runtimeType}(args=$args)';
    return route.runtimeType.toString();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    AppLog.navigator(
      'NavigatorObserver.didPush',
      _label(route),
      previousRoute != null ? _label(previousRoute) : null,
    );
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    AppLog.navigator(
      'NavigatorObserver.didPop',
      _label(route),
      previousRoute != null ? _label(previousRoute) : null,
    );
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    AppLog.navigator(
      'NavigatorObserver.didReplace',
      newRoute != null ? _label(newRoute) : '(null)',
      oldRoute != null ? _label(oldRoute) : null,
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    AppLog.navigator(
      'NavigatorObserver.didRemove',
      _label(route),
      previousRoute != null ? _label(previousRoute) : null,
    );
  }
}
