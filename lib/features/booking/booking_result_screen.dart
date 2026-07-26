import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/booking.dart';
import '../../core/models/facility.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_theme.dart';

/// Shown right after a booking is created. Confirms the token number,
/// expected time, and cash amount due — and shows the QR ticket the
/// facility scans at check-in.
class BookingResultScreen extends ConsumerWidget {
  final Booking booking;
  final Facility facility;
  final Doctor doctor;

  const BookingResultScreen({
    super.key,
    required this.booking,
    required this.facility,
    required this.doctor,
  });

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEEE, d MMM yyyy').format(d);
  }

  String _stripDataUrl(String value) {
    final idx = value.indexOf(',');
    return idx != -1 && value.startsWith('data:')
        ? value.substring(idx + 1)
        : value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: tokens.successSoft,
                    child: Icon(Icons.check_rounded,
                        size: 32, color: tokens.successColor),
                  ),
                  const SizedBox(height: 12),
                  Text('Appointment booked!',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Show the QR code below at the reception desk.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Your token', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('#${booking.tokenNumber}',
                        style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 16),
                    if (booking.qrCodeBase64 != null &&
                        booking.qrCodeBase64!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(kRadiusSm),
                        child: Image.memory(
                          base64Decode(_stripDataUrl(booking.qrCodeBase64!)),
                          width: 200,
                          height: 200,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.qr_code_2_rounded,
                              size: 120,
                              color: tokens.text3),
                        ),
                      )
                    else
                      Icon(Icons.qr_code_2_rounded,
                          size: 120, color: tokens.text3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                        icon: Icons.medical_services_outlined,
                        label: 'Doctor',
                        value: '${doctor.fullName} · ${doctor.specialty}'),
                    const Divider(height: 20),
                    _DetailRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Facility',
                        value: facility.name),
                    const Divider(height: 20),
                    _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Patient',
                        value: booking.patientName),
                    const Divider(height: 20),
                    _DetailRow(
                        icon: Icons.event_rounded,
                        label: 'Date',
                        value: _formatDate(booking.appointmentDate)),
                    const Divider(height: 20),
                    _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Expected time',
                        value: booking.expectedTime),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Amount due (cash)',
                      value: '₹${booking.bookingFee.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.bookings),
              child: const Text('View my bookings'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
