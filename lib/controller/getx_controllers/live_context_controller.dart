import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../utils/app_log.dart';

class LiveContextController extends GetxController {
  final now = DateTime.now().obs;
  final cityLabel = RxnString();
  final temperatureC = RxnDouble();
  final weatherLabel = RxnString(); // Frío / Calor / Ambas
  final timeOfDayLabel = RxnString(); // Día / Noche

  Timer? _tick;

  @override
  void onInit() {
    super.onInit();
    if (!Get.testMode) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = DateTime.now();
        _deriveTimeOfDay();
      });
    }
    _deriveTimeOfDay();
    if (!Get.testMode) {
      _refreshLocationAndWeather();
    }
  }

  @override
  void onClose() {
    _tick?.cancel();
    super.onClose();
  }

  void _deriveTimeOfDay() {
    final h = now.value.hour;
    final isDay = h >= 6 && h < 19;
    timeOfDayLabel.value = isDay ? 'Día' : 'Noche';
  }

  @override
  Future<void> refresh() async {
    await _refreshLocationAndWeather(force: true);
  }

  Future<void> _refreshLocationAndWeather({bool force = false}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        AppLog.warning('LiveContext: location services disabled');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        AppLog.warning('LiveContext: location permission denied', '$perm');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );

      await _reverseGeocode(pos.latitude, pos.longitude);
      await _fetchWeather(pos.latitude, pos.longitude, force: force);
    } catch (e, st) {
      AppLog.warning('LiveContext: refresh failed', '$e\n$st');
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lon);
      if (marks.isEmpty) return;
      final p = marks.first;
      final city = (p.locality ?? p.subAdministrativeArea ?? p.administrativeArea)
              ?.trim() ??
          '';
      if (city.isNotEmpty) {
        cityLabel.value = city;
      }
    } catch (e) {
      // Non-critical
    }
  }

  Future<void> _fetchWeather(
    double lat,
    double lon, {
    required bool force,
  }) async {
    // Use free Open-Meteo (no API key).
    // Cache lightly by only refreshing when forced or empty.
    if (!force && temperatureC.value != null) return;
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon&current=temperature_2m'
      '&temperature_unit=celsius',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        AppLog.warning(
          'LiveContext: open-meteo http error',
          '${res.statusCode} ${res.reasonPhrase}',
        );
        return;
      }
      final body = res.body;
      // Very small JSON, parse manually to avoid extra dependency.
      final marker = '"temperature_2m":';
      final i = body.indexOf(marker);
      if (i < 0) return;
      final start = i + marker.length;
      var end = start;
      while (end < body.length &&
          (body.codeUnitAt(end) == 32 ||
              body.codeUnitAt(end) == 9 ||
              body.codeUnitAt(end) == 10 ||
              body.codeUnitAt(end) == 13)) {
        end++;
      }
      var j = end;
      while (j < body.length) {
        final c = body.codeUnitAt(j);
        if ((c >= 48 && c <= 57) || c == 45 || c == 46) {
          j++;
          continue;
        }
        break;
      }
      final raw = body.substring(end, j).trim();
      final t = double.tryParse(raw);
      if (t == null) return;
      temperatureC.value = t;
      weatherLabel.value = _deriveWeatherLabel(t);
    } catch (e, st) {
      AppLog.warning('LiveContext: open-meteo failed', '$e\n$st');
    }
  }

  static String _deriveWeatherLabel(double tempC) {
    if (tempC <= 20) return 'Frío';
    if (tempC >= 27) return 'Calor';
    return 'Ambas';
  }
}
