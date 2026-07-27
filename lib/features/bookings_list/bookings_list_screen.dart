import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/booking.dart';
import '../../core/repositories/bookings_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/login_screen.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(
            message: 'Could not load bookings',
            onRetry: () => ref.invalidate(myBookingsProvider)),
        data: (bookings) {
          final all = [...bookings]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final upcoming = bookings.where((b) => isUpcoming(b.status)).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          final completed = bookings
              .where((b) => b.status == BookingStatus.completed)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final cancelled = bookings
              .where((b) =>
                  b.status == BookingStatus.cancelled ||
                  b.status == BookingStatus.noShow)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingsTab(bookings: all, emptyMessage: 'No bookings yet.'),
              _BookingsTab(
                  bookings: upcoming,
                  emptyMessage: 'No upcoming bookings yet.'),
              _BookingsTab(
                  bookings: completed,
                  emptyMessage: 'No completed bookings yet.'),
              _BookingsTab(
                  bookings: cancelled, emptyMessage: 'No cancelled bookings.'),
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

    final upcoming = bookings.where(isUpcomingBooking).toList();
    final rest = bookings.where((b) => !isUpcomingBooking(b)).toList();
    final featured = upcoming.isNotEmpty ? upcoming.first : null;
    final remainingUpcoming =
        upcoming.length > 1 ? upcoming.sublist(1) : <Booking>[];
    final previous = [...remainingUpcoming, ...rest];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myBookingsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (featured != null) ...[
            Text('Upcoming Booking',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _FeaturedBookingCard(booking: featured),
            const SizedBox(height: 20),
          ],
          if (previous.isNotEmpty) ...[
            Text(featured != null ? 'Previous Bookings' : 'Bookings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...previous.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BookingListTile(booking: b),
                )),
          ],
        ],
      ),
    );
  }
}

bool isUpcomingBooking(Booking b) => isUpcoming(b.status);

Color statusColor(BuildContext context, BookingStatus s) {
  final tokens = context.tokens;
  switch (s) {
    case BookingStatus.confirmed:
    case BookingStatus.checkedIn:
    case BookingStatus.inProgress:
      return tokens.successColor;
    case BookingStatus.completed:
      return tokens.successColor;
    case BookingStatus.cancelled:
    case BookingStatus.noShow:
      return tokens.dangerColor;
    case BookingStatus.pending:
      return tokens.accentColor;
  }
}

Color statusBg(BuildContext context, BookingStatus s) {
  final tokens = context.tokens;
  switch (s) {
    case BookingStatus.confirmed:
    case BookingStatus.checkedIn:
    case BookingStatus.inProgress:
      return tokens.successSoft;
    case BookingStatus.completed:
      return tokens.successSoft;
    case BookingStatus.cancelled:
    case BookingStatus.noShow:
      return tokens.dangerSoft;
    case BookingStatus.pending:
      return tokens.accentSoft;
  }
}

String formatBookingDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return DateFormat('d MMM yyyy, EEE').format(d);
}

/// Highlighted card for the next upcoming booking — mirrors the reference
/// design's hospital-icon card with Token No. / Booking ID + View Details.
class _FeaturedBookingCard extends ConsumerWidget {
  final Booking booking;
  const _FeaturedBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tokens.dangerSoft,
                      borderRadius: BorderRadius.circular(kRadiusSm),
                    ),
                    child: Icon(Icons.local_hospital_rounded,
                        color: tokens.dangerColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            booking.facilityName.isNotEmpty
                                ? booking.facilityName
                                : 'Facility',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text('General Physician',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: bookingStatusLabel(booking.status),
                    color: statusColor(context, booking.status),
                    background: statusBg(context, booking.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _iconLine(
                  context,
                  Icons.person_outline_rounded,
                  booking.doctorName.isNotEmpty
                      ? 'Dr. ${booking.doctorName}'
                      : 'Doctor'),
              const SizedBox(height: 6),
              _iconLine(context, Icons.event_rounded,
                  '${formatBookingDate(booking.appointmentDate)} • ${booking.expectedTime}'),
              const SizedBox(height: 6),
              if (booking.facilityAddress.isNotEmpty)
                _iconLine(context, Icons.location_on_outlined,
                    booking.facilityAddress),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Token No.', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text('#${booking.tokenNumber}',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking ID', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(
                            booking.id.length > 8
                                ? booking.id.substring(0, 8).toUpperCase()
                                : booking.id,
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailScreen(bookingId: booking.id))),
                    child: const Text('View Details'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  QueueStatusScreen(booking: booking))),
                      icon: const Icon(Icons.sensors_rounded, size: 18),
                      label: const Text('Live Queue'),
                    ),
                  ),
                  if (booking.status != BookingStatus.inProgress)
                    TextButton(
                      onPressed: () => _confirmCancel(context, ref),
                      style: TextButton.styleFrom(
                          foregroundColor: tokens.dangerColor),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconLine(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.tokens.text3),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
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

/// Compact row used for previous / non-featured bookings — mirrors the
/// reference design's colored type-icon list items.
class _BookingListTile extends ConsumerWidget {
  final Booking booking;
  const _BookingListTile({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: booking.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.primarySoft,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                child: Icon(Icons.local_hospital_rounded,
                    color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              booking.facilityName.isNotEmpty
                                  ? booking.facilityName
                                  : 'Booking',
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis),
                        ),
                        StatusPill(
                          label: bookingStatusLabel(booking.status),
                          color: statusColor(context, booking.status),
                          background: statusBg(context, booking.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (booking.doctorName.isNotEmpty)
                      Text(booking.doctorName,
                          style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                        '${formatBookingDate(booking.appointmentDate)} • ${booking.expectedTime}',
                        style: theme.textTheme.bodySmall),
                    if (booking.facilityAddress.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(booking.facilityAddress,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.text3),
            ],
          ),
        ),
      ),
    );
  }
}
