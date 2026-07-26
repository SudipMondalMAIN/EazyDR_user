import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../core_providers.dart';

class AppLocation {
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isGps;

  AppLocation(
      {required this.city, this.latitude, this.longitude, required this.isGps});
}

class LocationNotifier extends AsyncNotifier<AppLocation> {
  @override
  Future<AppLocation> build() async {
    return _detect();
  }

  Future<AppLocation> _detect() async {
    final storage = ref.read(localStorageProvider);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback(storage.lastCity);
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
      String cityName = 'Current location';
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = (p.locality?.isNotEmpty == true
              ? p.locality!
              : p.subAdministrativeArea ?? p.administrativeArea ?? cityName);
        }
      } catch (_) {
        // reverse geocoding failed — keep coordinates, use a generic label
      }
      await storage.setLastCity(cityName);
      return AppLocation(
          city: cityName,
          latitude: position.latitude,
          longitude: position.longitude,
          isGps: true);
    } catch (_) {
      return _fallback(storage.lastCity);
    }
  }

  AppLocation _fallback(String? lastCity) {
    return AppLocation(city: lastCity ?? 'Bolpur', isGps: false);
  }

  Future<void> setManualCity(String city) async {
    final storage = ref.read(localStorageProvider);
    await storage.setLastCity(city);
    state = AsyncData(AppLocation(city: city, isGps: false));
  }

  Future<void> redetect() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_detect);
  }
}

final locationProvider =
    AsyncNotifierProvider<LocationNotifier, AppLocation>(LocationNotifier.new);
