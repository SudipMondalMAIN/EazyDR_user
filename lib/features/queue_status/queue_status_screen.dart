import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/booking.dart';
import '../../core/repositories/bookings_repository.dart';
import '../../core/theme/app_theme.dart';

/// Full-page live status view for one booking — shows which token is
/// currently being seen, how many patients are ahead, and a rough wait
/// estimate. Polls the backend every 15s while the screen is open so it
/// stays current without the user having to pull-to-refresh.
class QueueStatusScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const QueueStatusScreen({super.key, required this.booking});

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
    _fetch();
    _timer = Timer.periodic(_pollInterval, (_) => _fetch(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final status = await ref.read(bookingsRepositoryProvider).getQueueStatus(widget.booking.id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Status'),
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
          Center(child: Text('Could not load live status', style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 8),
          Center(
            child: TextButton(onPressed: () => _fetch(), child: const Text('Retry')),
          ),
        ],
      );
    }

    final status = _status!;
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(status.doctorName.isNotEmpty ? status.doctorName : 'Doctor', style: theme.textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(status.facilityName, style: theme.textTheme.bodyMedium?.copyWith(color: tokens.text3)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Now serving', style: theme.textTheme.labelLarge?.copyWith(color: tokens.text3)),
                const SizedBox(height: 8),
                Text(
                  status.currentToken != null ? '#${status.currentToken}' : '—',
                  style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
                if (status.currentToken == null) ...[
                  const SizedBox(height: 4),
                  Text('Not started yet', style: theme.textTheme.bodySmall?.copyWith(color: tokens.text3)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(context, label: 'Your token', value: '#${status.yourToken}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(context, label: 'Patients ahead', value: '${status.patientsAhead}'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _statCard(
          context,
          label: 'Estimated wait',
          value: _isFinished
              ? '—'
              : (status.estimatedWaitMinutes != null ? '~${status.estimatedWaitMinutes} min' : 'Not available'),
          fullWidth: true,
        ),
        const SizedBox(height: 20),
        if (_isFinished)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: tokens.primarySoft, borderRadius: BorderRadius.circular(kRadiusSm)),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('This booking is ${bookingStatusLabel(status.status).toLowerCase()} — live tracking has ended.')),
              ],
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

  Widget _statCard(BuildContext context, {required String label, required String value, bool fullWidth = false}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: context.tokens.text3)),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
