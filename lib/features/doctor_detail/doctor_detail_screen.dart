import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/facility.dart';
import '../../core/models/misc_models.dart';
import '../../core/repositories/facilities_repository.dart';
import '../../core/repositories/misc_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_screen.dart';
import '../booking/booking_screen.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DoctorDetailScreen extends ConsumerWidget {
  final Doctor doctor;
  final Facility facility;
  const DoctorDetailScreen({super.key, required this.doctor, required this.facility});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(doctorAvailabilityProvider(doctor.id));
    final ratingAsync = ref.watch(doctorRatingSummaryProvider(doctor.id));
    final reviewsAsync = ref.watch(doctorReviewsProvider(doctor.id));
    final favoritesAsync = ref.watch(myFavoritesProvider);
    final auth = ref.watch(authProvider);

    final favorite = favoritesAsync.valueOrNull?.where((f) => f.targetType == FavoriteTargetType.doctor && f.targetId == doctor.id);
    final isFav = favorite != null && favorite.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: doctor.photoUrl != null ? NetworkImage(doctor.photoUrl!) : null,
                child: doctor.photoUrl == null ? const Icon(Icons.person, size: 32) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.fullName, style: Theme.of(context).textTheme.headlineSmall),
                    Text(doctor.specialty, style: Theme.of(context).textTheme.bodyMedium),
                    Text(doctor.qualification, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    ratingAsync.when(
                      data: (r) => Text(
                        r.totalReviews == 0 ? 'No ratings yet' : '⭐ ${r.averageRating?.toStringAsFixed(1)} (${r.totalReviews})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? context.tokens.dangerColor : null),
                onPressed: () async {
                  final repo = ref.read(favoritesRepositoryProvider);
                  if (isFav) {
                    await repo.remove(favorite!.first.id);
                  } else {
                    await repo.add(FavoriteTargetType.doctor, doctor.id);
                  }
                  ref.invalidate(myFavoritesProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_hospital_outlined),
              title: Text(facility.name),
              subtitle: Text(facility.address),
            ),
          ),
          const SectionHeader(title: 'Availability'),
          availabilityAsync.when(
            data: (slots) {
              final active = slots.where((s) => !s.isLeave).toList();
              if (active.isEmpty) return const EmptyView(message: 'No availability listed yet.');
              return Column(
                children: active
                    .map((s) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.schedule_rounded),
                            title: Text(s.dayOfWeek != null ? _dayNames[s.dayOfWeek!] : 'Every day'),
                            subtitle: Text('${s.startTime} – ${s.endTime}'),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const LoadingView(),
            error: (_, __) => const EmptyView(message: 'Availability unavailable right now.'),
          ),
          const SectionHeader(title: 'Consultation fee'),
          Text('₹${doctor.consultationFee.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge),
          const SectionHeader(title: 'Patient reviews'),
          reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) return const EmptyView(message: 'No reviews yet.');
              return Column(
                children: reviews
                    .take(5)
                    .map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 16, color: context.tokens.accentColor))),
                                if (r.comment != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.comment!)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const LoadingView(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              if (auth.status != SessionStatus.loggedIn) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
                return;
              }
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingScreen(doctor: doctor, facility: facility)));
            },
            child: const Text('Book appointment'),
          ),
        ),
      ),
    );
  }
}
