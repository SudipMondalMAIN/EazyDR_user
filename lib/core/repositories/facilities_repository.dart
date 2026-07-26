import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/facility.dart';
import '../models/misc_models.dart';

class FacilitySearchParams {
  final String? query;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final String? city;
  final FacilityType? facilityType;

  FacilitySearchParams(
      {this.query,
      this.latitude,
      this.longitude,
      this.radiusKm = 5.0,
      this.city,
      this.facilityType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacilitySearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusKm == other.radiusKm &&
          city == other.city &&
          facilityType == other.facilityType;

  @override
  int get hashCode =>
      Object.hash(query, latitude, longitude, radiusKm, city, facilityType);
}

class FacilitiesRepository {
  final Ref ref;
  FacilitiesRepository(this.ref);

  Future<List<Facility>> search(FacilitySearchParams params) async {
    final api = ref.read(apiClientProvider);
    final query = <String, dynamic>{'radius_km': params.radiusKm};
    if (params.query != null && params.query!.isNotEmpty)
      query['query'] = params.query;
    if (params.latitude != null) query['latitude'] = params.latitude;
    if (params.longitude != null) query['longitude'] = params.longitude;
    if (params.city != null && params.city!.isNotEmpty)
      query['city'] = params.city;
    final res = await api.get('/api/v1/facilities/search', query: query);
    var results = (res.data as List)
        .map((e) => Facility.fromJson(e as Map<String, dynamic>))
        .toList();
    if (params.facilityType != null) {
      results =
          results.where((f) => f.facilityType == params.facilityType).toList();
    }
    return results;
  }

  Future<Facility> getById(String id) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/facilities/$id');
    return Facility.fromJson(res.data);
  }

  Future<List<Doctor>> doctorsForFacility(String facilityId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/facilities/$facilityId/doctors');
    return (res.data as List)
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AvailabilitySlot>> doctorAvailability(String doctorId) async {
    final api = ref.read(apiClientProvider);
    final res =
        await api.get('/api/v1/facilities/doctors/$doctorId/availability');
    return (res.data as List)
        .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final facilitiesRepositoryProvider =
    Provider((ref) => FacilitiesRepository(ref));

final facilitySearchProvider =
    FutureProvider.family<List<Facility>, FacilitySearchParams>(
        (ref, params) => ref.read(facilitiesRepositoryProvider).search(params));

final facilityDetailProvider = FutureProvider.family<Facility, String>(
    (ref, id) => ref.read(facilitiesRepositoryProvider).getById(id));

final facilityDoctorsProvider = FutureProvider.family<List<Doctor>, String>(
    (ref, facilityId) =>
        ref.read(facilitiesRepositoryProvider).doctorsForFacility(facilityId));

final doctorAvailabilityProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>((ref, doctorId) =>
        ref.read(facilitiesRepositoryProvider).doctorAvailability(doctorId));
