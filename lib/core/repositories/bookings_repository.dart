import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/booking.dart';

class BookingsRepository {
  final Ref ref;
  BookingsRepository(this.ref);

  Future<Booking> create({
    required String facilityId,
    required String doctorId,
    required String patientName,
    required String patientPhone,
    required String patientAddress,
    required String appointmentDate,
  }) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/bookings', data: {
      'facility_id': facilityId,
      'doctor_id': doctorId,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'patient_address': patientAddress,
      'appointment_date': appointmentDate,
      'payment_mode':
          'cash', // cash-only — online/Paytm is disabled pending gateway approval
    });
    return Booking.fromJson(res.data);
  }

  Future<List<Booking>> myBookings() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/bookings/my');
    return (res.data as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> getReceipt(String bookingId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/bookings/$bookingId/receipt');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<QueueStatus> getQueueStatus(String bookingId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/bookings/$bookingId/queue-status');
    return QueueStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> cancel(String bookingId,
      {String? reason}) async {
    final api = ref.read(apiClientProvider);
    final res = await api
        .post('/api/v1/bookings/$bookingId/cancel', data: {'reason': reason});
    return res.data as Map<String, dynamic>;
  }
}

final bookingsRepositoryProvider = Provider((ref) => BookingsRepository(ref));

final myBookingsProvider = FutureProvider<List<Booking>>(
    (ref) => ref.read(bookingsRepositoryProvider).myBookings());

final bookingReceiptProvider = FutureProvider.family<Booking, String>(
    (ref, bookingId) =>
        ref.read(bookingsRepositoryProvider).getReceipt(bookingId));
