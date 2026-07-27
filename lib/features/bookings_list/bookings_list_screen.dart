import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/booking.dart';
import '../../core/repositories/bookings_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_screen.dart';
import '../booking_detail/booking_detail_screen.dart';
import '../queue_status/queue_status_screen.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen>
    with SingleTickerProviderStateMixin {
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
                Icon(Icons.calendar_month_rounded,
                    size: 40, color: context.tokens.text3),
                const SizedBox(height: 12),
                Text('Log in to see your bookings',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen())),
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
        error: (e, _) => ErrorRetryView(
            message: 'Could not load bookings',
            onRetry: () => ref.invalidate(myBookingsProvider)),
        data: (bookings) {
          final upcoming = bookings.where((b) => isUpcoming(b.status)).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          final past = bookings.where((b) => !isUpcoming(b.status)).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingsTab(
                  bookings: upcoming,
                  emptyMessage: 'No upcoming bookings yet.'),
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
        child: ListView(children: [
          EmptyView(message: emptyMessage, icon: Icons.calendar_month_outlined)
        ]),
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
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: booking.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Token #${booking.tokenNumber}',
                      style: theme.textTheme.titleMedium),
                  StatusPill(
                    label: bookingStatusLabel(booking.status),
                    color: _statusColor(context, booking.status),
                    background: _statusBg(context, booking.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.event_rounded,
                    size: 16, color: context.tokens.text3),
                const SizedBox(width: 6),
                Text(dateLabel, style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.schedule_rounded,
                    size: 16, color: context.tokens.text3),
                const SizedBox(width: 6),
                Text(booking.expectedTime, style: theme.textTheme.bodySmall),
              ]),
              const SizedBox(height: 4),
              Text('Patient: ${booking.patientName}',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                  'Booking fee ₹${booking.bookingFee.toStringAsFixed(0)} · Cash',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
              if (isUpcoming(booking.status)) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => QueueStatusScreen(booking: booking)),
                    ),
                    icon: const Icon(Icons.sensors_rounded, size: 18),
                    label: const Text('Live Status'),
                  ),
                ),
              ],
              if (isUpcoming(booking.status) &&
                  booking.status != BookingStatus.inProgress) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => _confirmCancel(context, ref),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: context.tokens.dangerColor),
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled')));
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
