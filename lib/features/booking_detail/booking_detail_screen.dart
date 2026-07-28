import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/booking.dart';
import '../../core/models/facility.dart';
import '../../core/repositories/bookings_repository.dart';
import '../../core/repositories/facilities_repository.dart';
import '../../core/services/receipt_pdf_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../facility_detail/facility_detail_screen.dart';
import '../queue_status/queue_status_screen.dart';

/// Full-page booking details — QR to check in, doctor/facility/appointment
/// info, payment summary, and cancel/receipt actions. Reached by tapping a
/// booking card in "My Bookings".
class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(bookingReceiptProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: receiptAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(
          message: 'Could not load booking details',
          onRetry: () => ref.invalidate(bookingReceiptProvider(bookingId)),
        ),
        data: (booking) => _BookingDetailBody(booking: booking),
      ),
    );
  }
}

class _BookingDetailBody extends ConsumerWidget {
  final Booking booking;
  const _BookingDetailBody({required this.booking});

  Color _statusColor(BuildContext context, BookingStatus s) {
    final tokens = context.tokens;
    switch (s) {
      case BookingStatus.confirmed:
      case BookingStatus.checkedIn:
      case BookingStatus.inProgress:
        return tokens.successColor;
      case BookingStatus.completed:
        return Theme.of(context).colorScheme.primary;
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return tokens.dangerColor;
      case BookingStatus.pending:
        return tokens.accentColor;
    }
  }

  Color _statusBg(BuildContext context, BookingStatus s) {
    final tokens = context.tokens;
    switch (s) {
      case BookingStatus.confirmed:
      case BookingStatus.checkedIn:
      case BookingStatus.inProgress:
        return tokens.successSoft;
      case BookingStatus.completed:
        return tokens.primarySoft;
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return tokens.dangerSoft;
      case BookingStatus.pending:
        return tokens.accentSoft;
    }
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEE, d MMM, y').format(d);
  }

  String _formatBookedOn(DateTime dt) => DateFormat('d MMM, h:mm a').format(dt);

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
    final facilityAsync = ref.watch(facilityDetailProvider(booking.facilityId));
    final doctorsAsync = ref.watch(facilityDoctorsProvider(booking.facilityId));

    final doctorName = doctorsAsync.maybeWhen(
      data: (doctors) {
        final match = doctors.where((d) => d.id == booking.doctorId);
        return match.isNotEmpty ? match.first.fullName : null;
      },
      orElse: () => null,
    );
    final facilityName =
        facilityAsync.maybeWhen(data: (f) => f.name, orElse: () => null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: StatusPill(
            label: bookingStatusLabel(booking.status),
            color: _statusColor(context, booking.status),
            background: _statusBg(context, booking.status),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (booking.qrCodeBase64 != null &&
                    booking.qrCodeBase64!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(kRadiusSm),
                    child: Image.memory(
                      base64Decode(_stripDataUrl(booking.qrCodeBase64!)),
                      width: 200,
                      height: 200,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.qr_code_2_rounded, size: 140),
                    ),
                  )
                else
                  Icon(Icons.qr_code_2_rounded, size: 140, color: tokens.text3),
                const SizedBox(height: 10),
                Text('Scan at the facility desk to check in',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('Token #${booking.tokenNumber}',
                    style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Appointment'),
        Card(
          child: Column(
            children: [
              _DetailRow(label: 'Doctor', value: doctorName ?? '—'),
              const Divider(height: 1),
              _DetailRow(
                label: 'Facility',
                value: facilityName ?? '—',
                onTap: facilityName == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FacilityDetailScreen(
                            facilityId: booking.facilityId))),
              ),
              const Divider(height: 1),
              _DetailRow(
                  label: 'Date', value: _formatDate(booking.appointmentDate)),
              const Divider(height: 1),
              _DetailRow(label: 'Expected time', value: booking.expectedTime),
              const Divider(height: 1),
              _DetailRow(label: 'Patient', value: booking.patientName),
              const Divider(height: 1),
              _DetailRow(
                  label: 'Booked on',
                  value: _formatBookedOn(booking.createdAt)),
            ],
          ),
        ),
        const SectionHeader(title: 'Payment'),
        Card(
          child: Column(
            children: [
              _DetailRow(
                  label: 'Booking fee',
                  value: '₹${booking.bookingFee.toStringAsFixed(0)}'),
              const Divider(height: 1),
              _DetailRow(
                  label: 'Mode',
                  value: booking.paymentMode == 'cash'
                      ? 'Cash at facility'
                      : booking.paymentMode),
            ],
          ),
        ),
        const SectionHeader(title: 'Booking ID'),
        Card(
          child: ListTile(
            title: Text(booking.orderId, style: theme.textTheme.bodySmall),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: booking.orderId));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking ID copied')));
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (isUpcoming(booking.status)) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.sensors_rounded),
              label: const Text('Live Status'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => QueueStatusScreen(booking: booking)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Receipt (PDF)'),
                onPressed: () => _downloadReceipt(context, ref),
              ),
            ),
            if (isUpcoming(booking.status) &&
                booking.status != BookingStatus.inProgress) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.dangerColor),
                  onPressed: () => _confirmCancel(context, ref),
                  child: const Text('Cancel booking'),
                ),
              ),
            ],
          ],
        ),
        if (isUpcoming(booking.status) &&
            booking.status != BookingStatus.inProgress) ...[
          const SizedBox(height: 12),
          Text(
            'Free cancellation until 5 hours before your slot. Later cancellations may have a deduction; refunds are credited as reward points.',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.text3),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _downloadReceipt(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final fullBooking =
          await ref.read(bookingsRepositoryProvider).getReceipt(booking.id);
      await ReceiptPdfService.shareReceipt(fullBooking);
      if (context.mounted) Navigator.pop(context); // close loading dialog
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate receipt: $e')),
        );
      }
    }
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
            'This will cancel your appointment. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No, keep it')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(bookingsRepositoryProvider).cancel(booking.id);
                ref.invalidate(myBookingsProvider);
                ref.invalidate(bookingReceiptProvider(booking.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled')));
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not cancel: $e')));
                }
              }
            },
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _DetailRow({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return ListTile(
      onTap: onTap,
      title: Text(label,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.text3)),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: onTap != null ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}
