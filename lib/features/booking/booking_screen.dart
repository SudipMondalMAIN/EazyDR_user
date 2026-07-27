import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/facility.dart';
import '../../core/repositories/bookings_repository.dart';
import 'booking_result_screen.dart';

/// Booking flow — the patient never picks a time. The backend computes
/// expected_time from doctor availability + token position; this screen
/// only collects patient details and the appointment date, then confirms
/// cash payment (no online/Paytm option is shown — disabled pending
/// gateway approval).
class BookingScreen extends ConsumerStatefulWidget {
  final Doctor doctor;
  final Facility facility;
  const BookingScreen(
      {super.key, required this.doctor, required this.facility});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final _addressCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all patient details');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await ref.read(bookingsRepositoryProvider).create(
            facilityId: widget.facility.id,
            doctorId: widget.doctor.id,
            patientName: _nameCtrl.text.trim(),
            patientPhone: _phoneCtrl.text.trim(),
            patientAddress: _addressCtrl.text.trim(),
            appointmentDate: DateFormat('yyyy-MM-dd').format(_date),
          );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BookingResultScreen(
              booking: booking,
              facility: widget.facility,
              doctor: widget.doctor)));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.facility.photoUrl != null
                      ? Image.network(
                          widget.facility.photoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.local_hospital_outlined),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_hospital_outlined),
                        ),
                ),
                title: Text(widget.doctor.fullName),
                subtitle: Text(
                    '${widget.doctor.specialty} · ${widget.facility.name}'),
                trailing: Text(
                    '₹${widget.facility.bookingFee.toStringAsFixed(0)} fee'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Patient name')),
            const SizedBox(height: 12),
            TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Patient phone')),
            const SizedBox(height: 12),
            TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Patient address')),
            const SizedBox(height: 16),
            ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.event_rounded),
              title: const Text('Appointment date'),
              subtitle: Text(DateFormat('EEEE, d MMM yyyy').format(_date)),
              trailing:
                  TextButton(onPressed: _pickDate, child: const Text('Change')),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your token number and expected consultation time are computed automatically based on the doctor\'s queue — you do not choose a time slot.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Pay in cash at the facility')),
                    Text('₹${widget.facility.bookingFee.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _confirm,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm booking (Cash)'),
            ),
          ],
        ),
      ),
    );
  }
}
