import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/location/location_provider.dart';

/// Full-screen "choose on map" picker — center-fixed pin + drag-to-move,
/// search-by-name, and a "use current location" shortcut, mirroring the
/// Swiggy/Zomato location picker flow. Pushed from the home screen's
/// city picker sheet; pops `true` once a location is confirmed (the
/// caller doesn't need the value back — it's already saved via
/// [LocationNotifier.setPickedLocation]).
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();

  ll.LatLng _center =
      const ll.LatLng(23.6850, 90.3563); // Bangladesh centroid fallback
  String _address = 'Move the map to pick a location';
  bool _resolvingAddress = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initFromCurrentOrLastKnown();
  }

  Future<void> _initFromCurrentOrLastKnown() async {
    final existing = ref.read(locationProvider).valueOrNull;
    if (existing?.latitude != null && existing?.longitude != null) {
      _center = ll.LatLng(existing!.latitude!, existing.longitude!);
      _address = existing.city;
      setState(() {});
      return;
    }
    await _useCurrentLocation(recenter: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    // Only reverse-geocode once the user stops moving the map — avoids
    // firing a network lookup on every drag frame.
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      final c = _mapController.camera.center;
      _center = ll.LatLng(c.latitude, c.longitude);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), _reverseGeocode);
    }
  }

  Future<void> _reverseGeocode() async {
    setState(() => _resolvingAddress = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(_center.latitude, _center.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        setState(
            () => _address = parts.isNotEmpty ? parts : 'Selected location');
      }
    } catch (_) {
      setState(() => _address = 'Selected location');
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _useCurrentLocation({bool recenter = true}) async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Location permission is off — enable it to use GPS')));
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
      _center = ll.LatLng(position.latitude, position.longitude);
      if (recenter) {
        _mapController.move(_center, 16);
      }
      await _reverseGeocode();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not fetch current location')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _resolvingAddress = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        _center = ll.LatLng(loc.latitude, loc.longitude);
        _mapController.move(_center, 16);
        await _reverseGeocode();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No matching place found')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search failed — try again')));
      }
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  void _confirm() {
    ref.read(locationProvider.notifier).setPickedLocation(
          city: _address,
          latitude: _center.latitude,
          longitude: _center.longitude,
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.eazydoctor.user',
              ),
            ],
          ),

          // Fixed center pin — the map moves under it, not the other way round.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on_rounded,
                    size: 44, color: Colors.red),
              ),
            ),
          ),

          // Search bar + back button.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      elevation: 2,
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _searchAddress,
                        decoration: InputDecoration(
                          hintText: 'Search area, street, city…',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _resolvingAddress
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "Use current location" floating shortcut.
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton(
              heroTag: 'use_current_location',
              backgroundColor: Colors.white,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded,
                      color: Colors.black87),
            ),
          ),

          // Bottom sheet: resolved address + confirm button.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deliver to this location',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(_address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resolvingAddress ? null : _confirm,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Confirm Location'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
