import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/booking.dart';
import '../../core/repositories/bookings_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_screen.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (auth.status == SessionStatus.loggedOut) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded, size: 40, color: context.tokens.text3),
                const SizedBox(height: 12),
                Text('Log in to see your bookings', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(message: 'Could not load bookings', onRetry: () => ref.invalidate(myBookingsProvider)),
        data: (bookings) {
          final upcoming = bookings.where((b) => isUpcoming(b.status)).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          final past = bookings.where((b) => !isUpcoming(b.status)).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingsTab(bookings: upcoming, emptyMessage: 'No upcoming bookings yet.'),
              _BookingsTab(bookings: past, emptyMessage: 'No past bookings.'),
            ],
          );
        },
      ),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  final List<Booking> bookings;
  final String emptyMessage;
  const _BookingsTab({required this.bookings, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.invalidate(myBookingsProvider),
        child: ListView(children: [EmptyView(message: emptyMessage, icon: Icons.calendar_month_outlined)]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myBookingsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateLabel = _formatDate(booking.appointmentDate);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: () => _showTicket(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Token #${booking.tokenNumber}', style: theme.textTheme.titleMedium),
                  StatusPill(
                    label: bookingStatusLabel(booking.status),
                    color: _statusColor(context, booking.status),
                    background: _statusBg(context, booking.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.event_rounded, size: 16, color: context.tokens.text3),
                const SizedBox(width: 6),
                Text(dateLabel, style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.schedule_rounded, size: 16, color: context.tokens.text3),
                const SizedBox(width: 6),
                Text(booking.expectedTime, style: theme.textTheme.bodySmall),
              ]),
              const SizedBox(height: 4),
              Text('Patient: ${booking.patientName}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('Booking fee ₹${booking.bookingFee.toStringAsFixed(0)} · Cash',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
              if (isUpcoming(booking.status) && booking.status != BookingStatus.inProgress) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => _confirmCancel(context, ref),
                    style: OutlinedButton.styleFrom(foregroundColor: context.tokens.dangerColor),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('d MMM, EEE').format(d);
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This will cancel your appointment. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, keep it')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(bookingsRepositoryProvider).cancel(booking.id);
                ref.invalidate(myBookingsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel: $e')));
                }
              }
            },
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  void _showTicket(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your token', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('#${booking.tokenNumber}', style: Theme.of(ctx).textTheme.headlineLarge),
            const SizedBox(height: 16),
            if (booking.qrCodeBase64 != null && booking.qrCodeBase64!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(kRadiusSm),
                child: Image.memory(
                  base64Decode(_stripDataUrl(booking.qrCodeBase64!)),
                  width: 200,
                  height: 200,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Icon(Icons.qr_code_2_rounded, size: 120)),
                ),
              )
            else
              Icon(Icons.qr_code_2_rounded, size: 120, color: context.tokens.text3),
            const SizedBox(height: 16),
            Text('${_formatDate(booking.appointmentDate)} · ${booking.expectedTime}', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Show this at the reception desk', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ),
          ],
        ),
      ),
    );
  }

  String _stripDataUrl(String value) {
    final idx = value.indexOf(',');
    return idx != -1 && value.startsWith('data:') ? value.substring(idx + 1) : value;
  }
}
