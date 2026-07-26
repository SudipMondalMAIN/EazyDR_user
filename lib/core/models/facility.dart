enum FacilityType { nursingHome, doctorChamber, pharmacy }

FacilityType facilityTypeFromApi(String v) {
  switch (v) {
    case 'nursing_home':
      return FacilityType.nursingHome;
    case 'pharmacy':
      return FacilityType.pharmacy;
    case 'doctor_chamber':
    default:
      return FacilityType.doctorChamber;
  }
}

String facilityTypeToApi(FacilityType t) {
  switch (t) {
    case FacilityType.nursingHome:
      return 'nursing_home';
    case FacilityType.pharmacy:
      return 'pharmacy';
    case FacilityType.doctorChamber:
      return 'doctor_chamber';
  }
}

String facilityTypeLabel(FacilityType t) {
  switch (t) {
    case FacilityType.nursingHome:
      return 'Nursing Home';
    case FacilityType.pharmacy:
      return 'Pharmacy';
    case FacilityType.doctorChamber:
      return 'Doctor Chamber';
  }
}

class Facility {
  final String id;
  final String name;
  final FacilityType facilityType;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double bookingFee;
  final bool isVerified;
  final bool isActive;
  final bool isAdSponsored;
  final String? photoUrl;
  final double? distanceKm;
  final String? phone;
  final String? email;
  final String? description;
  final String? workingHours;

  Facility({
    required this.id,
    required this.name,
    required this.facilityType,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.bookingFee,
    required this.isVerified,
    required this.isActive,
    required this.isAdSponsored,
    this.photoUrl,
    this.distanceKm,
    this.phone,
    this.email,
    this.description,
    this.workingHours,
  });

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        facilityType: facilityTypeFromApi(json['facility_type']),
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        bookingFee: (json['booking_fee'] as num?)?.toDouble() ?? 0,
        isVerified: json['is_verified'] ?? false,
        isActive: json['is_active'] ?? true,
        isAdSponsored: json['is_ad_sponsored'] ?? false,
        photoUrl: json['photo_url'],
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        phone: json['phone'],
        email: json['email'],
        description: json['description'],
        workingHours: json['working_hours'],
      );
}

class Doctor {
  final String id;
  final String facilityId;
  final String fullName;
  final String qualification;
  final String specialty;
  final double consultationFee;
  final bool isActive;
  final String? photoUrl;

  Doctor({
    required this.id,
    required this.facilityId,
    required this.fullName,
    required this.qualification,
    required this.specialty,
    required this.consultationFee,
    required this.isActive,
    this.photoUrl,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'].toString(),
        facilityId: json['facility_id'].toString(),
        fullName: json['full_name'] ?? '',
        qualification: json['qualification'] ?? '',
        specialty: json['specialty'] ?? '',
        consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0,
        isActive: json['is_active'] ?? true,
        photoUrl: json['photo_url'],
      );
}

class AvailabilitySlot {
  final String id;
  final String doctorId;
  final int? dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final bool isLeave;
  final String? leaveDate;

  AvailabilitySlot({
    required this.id,
    required this.doctorId,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    required this.isLeave,
    this.leaveDate,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
        id: json['id'].toString(),
        doctorId: json['doctor_id'].toString(),
        dayOfWeek: json['day_of_week'],
        startTime: json['start_time'] ?? '',
        endTime: json['end_time'] ?? '',
        slotDurationMinutes: json['slot_duration_minutes'] ?? 15,
        isLeave: json['is_leave'] ?? false,
        leaveDate: json['leave_date'],
      );
}
