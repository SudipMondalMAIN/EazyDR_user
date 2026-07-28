enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  noShow
}

BookingStatus bookingStatusFromApi(String v) {
  switch (v) {
    case 'pending':
      return BookingStatus.pending;
    case 'confirmed':
      return BookingStatus.confirmed;
    case 'checked_in':
      return BookingStatus.checkedIn;
    case 'in_progress':
      return BookingStatus.inProgress;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    case 'no_show':
      return BookingStatus.noShow;
    default:
      return BookingStatus.pending;
  }
}

String bookingStatusLabel(BookingStatus s) {
  switch (s) {
    case BookingStatus.pending:
      return 'Pending';
    case BookingStatus.confirmed:
      return 'Confirmed';
    case BookingStatus.checkedIn:
      return 'Checked In';
    case BookingStatus.inProgress:
      return 'In Progress';
    case BookingStatus.completed:
      return 'Completed';
    case BookingStatus.cancelled:
      return 'Cancelled';
    case BookingStatus.noShow:
      return 'No Show';
  }
}

bool isUpcoming(BookingStatus s) =>
    s == BookingStatus.pending ||
    s == BookingStatus.confirmed ||
    s == BookingStatus.checkedIn ||
    s == BookingStatus.inProgress;

class Booking {
  final String id;
  final String facilityId;
  final String doctorId;
  final String patientName;
  final int tokenNumber;
  final String appointmentDate;
  final String expectedTime;
  final double bookingFee;
  final String paymentMode; // "cash" only, exposed in UI
  final BookingStatus status;
  final String qrUuid;
  final DateTime createdAt;
  final String? qrCodeBase64;
  final String doctorName;
  final String facilityName;
  final String facilityAddress;
  final String? facilityPhotoUrl;

  Booking({
    required this.id,
    required this.facilityId,
    required this.doctorId,
    required this.patientName,
    required this.tokenNumber,
    required this.appointmentDate,
    required this.expectedTime,
    required this.bookingFee,
    required this.paymentMode,
    required this.status,
    required this.qrUuid,
    required this.createdAt,
    this.qrCodeBase64,
    this.doctorName = '',
    this.facilityName = '',
    this.facilityAddress = '',
    this.facilityPhotoUrl,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'].toString(),
        facilityId: json['facility_id'].toString(),
        doctorId: json['doctor_id'].toString(),
        patientName: json['patient_name'] ?? '',
        tokenNumber: json['token_number'] ?? 0,
        appointmentDate: json['appointment_date'] ?? '',
        expectedTime: json['expected_time'] ?? '',
        bookingFee: (json['booking_fee'] as num?)?.toDouble() ?? 0,
        paymentMode: json['payment_mode'] ?? 'cash',
        status: bookingStatusFromApi(json['status']),
        qrUuid: json['qr_uuid'].toString(),
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        qrCodeBase64: json['qr_code_base64'],
        doctorName: json['doctor_name'] ?? '',
        facilityName: json['facility_name'] ?? '',
        facilityAddress: json['facility_address'] ?? '',
        facilityPhotoUrl: json['facility_photo_url'],
      );
}

class QueueStatus {
  final String bookingId;
  final String doctorName;
  final String facilityName;
  final String appointmentDate;
  final int yourToken;
  final BookingStatus status;
  final int? currentToken;
  final int patientsAhead;
  final int? estimatedWaitMinutes;
  final DateTime updatedAt;

  QueueStatus({
    required this.bookingId,
    required this.doctorName,
    required this.facilityName,
    required this.appointmentDate,
    required this.yourToken,
    required this.status,
    required this.currentToken,
    required this.patientsAhead,
    required this.estimatedWaitMinutes,
    required this.updatedAt,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) => QueueStatus(
        bookingId: json['booking_id'].toString(),
        doctorName: json['doctor_name'] ?? '',
        facilityName: json['facility_name'] ?? '',
        appointmentDate: json['appointment_date'] ?? '',
        yourToken: json['your_token'] ?? 0,
        status: bookingStatusFromApi(json['status']),
        currentToken: json['current_token'],
        patientsAhead: json['patients_ahead'] ?? 0,
        estimatedWaitMinutes: json['estimated_wait_minutes'],
        updatedAt:
            DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      );
}
