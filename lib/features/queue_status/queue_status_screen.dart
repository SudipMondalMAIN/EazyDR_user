import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/booking.dart';
import '../../core/repositories/bookings_repository.dart';
import '../../core/theme/app_theme.dart';

/// Live status — used two ways:
///  - with a `booking` passed in (from booking detail / bookings list): shows
///    that one booking's live queue status, polling every 15s.
///  - with no `booking` (used directly as a bottom-nav tab): lists all of
///    the user's currently-active bookings; tapping one pushes this same
///    screen again, this time with that booking set.
class QueueStatusScreen extends ConsumerStatefulWidget {
  final Booking? booking;
  const QueueStatusScreen({super.key, this.booking});

  @override
  ConsumerState<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends ConsumerState<QueueStatusScreen> {
  static const _pollInterval = Duration(seconds: 15);

  Timer? _timer;
  QueueStatus? _status;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _fetch();
      _timer = Timer.periodic(_pollInterval, (_) => _fetch(silent: true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    if (widget.booking == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final status = await ref
          .read(bookingsRepositoryProvider)
          .getQueueStatus(widget.booking!.id);
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool get _isFinished =>
      _status != null &&
      (_status!.status == BookingStatus.completed ||
          _status!.status == BookingStatus.cancelled ||
          _status!.status == BookingStatus.noShow);

  @override
  Widget build(BuildContext context) {
    if (widget.booking == null) return _buildListMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue'),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _fetch(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetch(),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildListMode(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load bookings: $e')),
        data: (bookings) {
          final active = bookings.where((b) => isUpcoming(b.status)).toList();
          if (active.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_off_rounded,
                        size: 40, color: context.tokens.text3),
                    const SizedBox(height: 12),
                    const Text('No active bookings right now'),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = active[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.sensors_rounded),
                  title: Text(b.facilityName.isNotEmpty
                      ? b.facilityName
                      : 'Token #${b.tokenNumber}'),
                  subtitle: Text(
                      '${bookingStatusLabel(b.status)} · ${b.appointmentDate}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QueueStatusScreen(booking: b))),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _status == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _status == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.wifi_off_rounded, size: 40, color: context.tokens.text3),
          const SizedBox(height: 12),
          Center(
              child: Text('Could not load live status',
                  style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 8),
          Center(
              child: TextButton(
                  onPressed: () => _fetch(), child: const Text('Retry'))),
        ],
      );
    }

    final status = _status!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final primary = theme.colorScheme.primary;

    // Best-effort queue-summary numbers derived from the fields the API
    // actually gives us (no separate "completed/total" endpoint yet).
    final remaining = status.patientsAhead;
    final completedSoFar =
        status.currentToken != null && status.currentToken! > 0
            ? status.currentToken! - 1
            : 0;
    final totalInQueue = status.yourToken > completedSoFar + remaining
        ? status.yourToken
        : completedSoFar + remaining + 1;
    final nextToken = (status.currentToken ?? 0) + 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top teal card: facility, doctor, token + ETA
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(kRadiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.local_hospital_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            status.facilityName.isNotEmpty
                                ? status.facilityName
                                : 'Facility',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        Text(
                            status.doctorName.isNotEmpty
                                ? 'Dr. ${status.doctorName}'
                                : 'Doctor',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9))),
                      ],
                    ),
                  ),
                  if (!_isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('Live',
                          style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: Colors.white.withOpacity(0.25), height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Token',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('#${status.yourToken}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated Wait',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _isFinished
                              ? '—'
                              : (status.estimatedWaitMinutes != null
                                  ? '${status.estimatedWaitMinutes} mins'
                                  : '—'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Current status
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Status', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  status.currentToken != null
                      ? 'Token #${status.currentToken} is in consultation'
                      : (_isFinished
                          ? 'This booking is ${bookingStatusLabel(status.status).toLowerCase()}'
                          : 'Not started yet'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 20, color: tokens.text3),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: primary,
                          inactiveTrackColor: tokens.surface2,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: totalInQueue > 0
                              ? (completedSoFar / totalInQueue).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: null,
                        ),
                      ),
                    ),
                    Icon(Icons.groups_rounded, size: 20, color: tokens.text3),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Next token: #$nextToken',
                      style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Queue summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Queue Summary', style: theme.textTheme.titleMedium),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _summaryStat(context,
                        label: 'Total in Queue', value: '$totalInQueue'),
                    _summaryStat(context,
                        label: 'Completed',
                        value: '$completedSoFar',
                        color: tokens.successColor),
                    _summaryStat(context,
                        label: 'Remaining',
                        value: '$remaining',
                        color: primary),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_isFinished)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: tokens.primarySoft,
                borderRadius: BorderRadius.circular(kRadiusSm)),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded,
                    color: primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                    child:
                        Text('You will be notified 30 mins before your turn.')),
              ],
            ),
          ),
        if (_isFinished)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: tokens.primarySoft,
                borderRadius: BorderRadius.circular(kRadiusSm)),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'This booking is ${bookingStatusLabel(status.status).toLowerCase()} — live tracking has ended.')),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // Need help card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: tokens.primarySoft, shape: BoxShape.circle),
                  child: Icon(Icons.headset_mic_rounded, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Need Help?', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                          'If you need any assistance, our support team is here to help you.',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('Call Support'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Updated ${DateFormat('h:mm:ss a').format(status.updatedAt.toLocal())} · refreshes every 15s',
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.text3),
          ),
        ),
      ],
    );
  }

  Widget _summaryStat(BuildContext context,
      {required String label, required String value, Color? color}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color ?? theme.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
