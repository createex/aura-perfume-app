import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../domain/perfume/perfume.dart';

/// English structured logs for navigation, taps, persistence, and catalog actions.
///
/// Emits to the Dart log stream (`dart:developer`), visible in the IDE / DevTools
/// and in Android `adb logcat` with tag prefix `AuraPerfume.*`.
///
/// Categories: `startup`, `navigation` (GetX + [Navigator] observer), `tap`,
/// `action`, `catalog`, `db` (SQLite), `io` (files / export paths), `input`,
/// `warning`.
///
/// Disabled in [kReleaseMode] unless you set [enabled] to true and rebuild.
class AppLog {
  AppLog._();

  static const String _scope = 'AuraPerfume';

  /// Master switch (still no logs in release unless you change [_active]).
  static bool enabled = true;

  static bool get _active => enabled && !kReleaseMode;

  static void _emit(String category, String message, {int level = 800}) {
    if (!_active) return;
    developer.log(message, name: '$_scope.$category', level: level);
  }

  static String _escape(String s) {
    final oneLine = s.replaceAll('\n', ' ');
    if (oneLine.length > 140) return '${oneLine.substring(0, 137)}...';
    return oneLine;
  }

  static Map<String, Object?> perfumeSummary(Perfume p) => {
        'id': p.id,
        'brand': p.brand,
        'name': p.name,
        'rating': p.rating,
        'imagePath': p.imagePath,
      };

  /// Richer row snapshot for persistence / import / export logs.
  static Map<String, Object?> perfumeSummaryDetailed(Perfume p) => {
        ...perfumeSummary(p),
        'vitrina': p.vitrina,
        'supplier': p.supplierOrOrigin,
        'profile': p.profile,
        'clothing': p.clothing,
        'diaNoche': p.diaNoche,
        'frioCalor': p.frioCalor,
        'reponer': p.reponer,
        'refillNeeded': p.refillNeeded,
        'topCollection': p.topCollection,
        'beach': p.beach,
        'outings': p.outings,
        'office': p.office,
        'family': p.family,
        'price': p.price,
      };

  static String _map(Map<String, Object?> m) {
    if (m.isEmpty) return '';
    final parts = <String>[];
    for (final e in m.entries) {
      final v = e.value;
      parts.add('${e.key}=${v is String ? _escape(v) : v}');
    }
    return parts.join(' | ');
  }

  static void startup(String message, [Map<String, Object?>? data]) {
    final extra = data == null || data.isEmpty ? '' : ' | ${_map(data)}';
    _emit('startup', message + extra);
  }

  static void routing({
    required String current,
    required String previous,
    bool? isBack,
    Object? args,
    bool? isBottomSheet,
    bool? isDialog,
  }) {
    if (!_active) return;
    final sb = StringBuffer('GetX routingCallback');
    sb.write(' | current=');
    sb.write(_escape(current));
    if (previous.isNotEmpty) {
      sb.write(' | previous=');
      sb.write(_escape(previous));
    }
    if (isBack == true) sb.write(' | action=POP');
    if (isDialog == true) sb.write(' | overlay=dialog');
    if (isBottomSheet == true) sb.write(' | overlay=bottomSheet');
    if (args != null) sb.write(' | routeArgs=$args');
    _emit('navigation', sb.toString());
  }

  /// Flutter [Navigator] observer (page stack), distinct from GetX callback.
  static void navigator(
    String action,
    String routeLabel, [
    String? previousLabel,
  ]) {
    if (!_active) return;
    final sb = StringBuffer(action);
    sb.write(' | route=');
    sb.write(_escape(routeLabel));
    if (previousLabel != null && previousLabel.isNotEmpty) {
      sb.write(' | previous=');
      sb.write(_escape(previousLabel));
    }
    _emit('navigation', sb.toString());
  }

  /// SQLite and local catalog persistence.
  static void db(String label, [Map<String, Object?>? data]) {
    final extra = data == null || data.isEmpty ? '' : ' | ${_map(data)}';
    _emit('db', label + extra);
  }

  /// Filesystem reads/writes (exports, migrations, etc.).
  static void io(String label, [Map<String, Object?>? data]) {
    final extra = data == null || data.isEmpty ? '' : ' | ${_map(data)}';
    _emit('io', label + extra);
  }

  static void navigate(String action, String target,
      [Map<String, Object?>? data]) {
    final extra = data == null || data.isEmpty ? '' : ' | ${_map(data)}';
    _emit('navigation', '$action → $target$extra');
  }

  static void tap(String screen, String label,
      [Map<String, Object?>? data]) {
    final extra = data == null || data.isEmpty ? '' : ' | ${_map(data)}';
    _emit('tap', '[$screen] $label$extra');
  }

  static void action(String label, [Map<String, Object?>? data]) {
    final extra = data == null || data.isEmpty ? '' : ' | ${_map(data)}';
    _emit('action', label + extra);
  }

  static void catalog(String label, [Map<String, Object?>? data]) {
    final extra = data == null || data.isEmpty ? '' : ' | ${_map(data)}';
    _emit('catalog', label + extra);
  }

  static void warning(String message, [Object? error]) {
    if (!_active) return;
    _emit(
      'warning',
      error == null ? message : '$message | error=$error',
      level: 900,
    );
  }

  static String? _lastSearchTrimmed;

  /// Avoids logging every keystroke: logs when trimmed query changes.
  static void librarySearchQueryChanged(String raw) {
    if (!_active) return;
    final t = raw.trim();
    if (t == _lastSearchTrimmed) return;
    _lastSearchTrimmed = t;
    _emit(
      'input',
      'Library search updated | trimmedLength=${t.length} | query="${_escape(t.isEmpty ? '(cleared)' : t)}"',
    );
  }
}
