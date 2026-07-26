import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/facility.dart';
import '../../core/models/misc_models.dart';
import '../../core/repositories/facilities_repository.dart';
import '../../core/repositories/misc_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../doctor_detail/doctor_detail_screen.dart';

class FacilityDetailScreen extends ConsumerWidget {
  final String facilityId;
  const FacilityDetailScreen({super.key, required this.facilityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityAsync = ref.watch(facilityDetailProvider(facilityId));
    final doctorsAsync = ref.watch(facilityDoctorsProvider(facilityId));
    final ratingAsync = ref.watch(facilityRatingSummaryProvider(facilityId));
    final favoritesAsync = ref.watch(myFavoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Facility')),
      body: facilityAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(message: 'Could not load facility', onRetry: () => ref.invalidate(facilityDetailProvider(facilityId))),
        data: (facility) {
          final favorite = favoritesAsync.valueOrNull?.where((f) => f.targetType == FavoriteTargetType.facility && f.targetId == facilityId);
          final isFav = favorite != null && favorite.isNotEmpty;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(facilityDetailProvider(facilityId));
              ref.invalidate(facilityDoctorsProvider(facilityId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(kRadius),
                      child: facility.photoUrl != null
                          ? Image.network(facility.photoUrl!, width: 84, height: 84, fit: BoxFit.cover)
                          : Container(width: 84, height: 84, color: context.tokens.surface2, child: const Icon(Icons.local_hospital_outlined)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(facility.name, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(facilityTypeLabel(facility.facilityType), style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            if (facility.isVerified) StatusPill(label: 'Verified', color: context.tokens.successColor, background: context.tokens.successSoft),
                            if (facility.isAdSponsored) StatusPill(label: 'Sponsored', color: context.tokens.accentColor, background: context.tokens.accentSoft),
                          ]),
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
                          await repo.add(FavoriteTargetType.facility, facilityId);
                        }
                        ref.invalidate(myFavoritesProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _InfoRow(icon: Icons.place_outlined, text: '${facility.address}, ${facility.city}'),
                      if (facility.workingHours != null) _InfoRow(icon: Icons.access_time_rounded, text: facility.workingHours!),
                      if (facility.phone != null) _InfoRow(icon: Icons.call_outlined, text: facility.phone!),
                      _InfoRow(icon: Icons.payments_outlined, text: 'Booking fee ₹${facility.bookingFee.toStringAsFixed(0)} · Cash on arrival'),
                      ratingAsync.when(
                        data: (r) => _InfoRow(
                          icon: Icons.star_rounded,
                          text: r.totalReviews == 0 ? 'No reviews yet' : '${r.averageRating?.toStringAsFixed(1)} · ${r.totalReviews} reviews',
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ]),
                  ),
                ),
                if (facility.description != null) ...[
                  const SizedBox(height: 12),
                  Text(facility.description!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SectionHeader(title: 'Doctors'),
                doctorsAsync.when(
                  data: (doctors) {
                    if (doctors.isEmpty) return const EmptyView(message: 'No doctors listed yet.');
                    return Column(
                      children: doctors
                          .map((d) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: d.photoUrl != null ? NetworkImage(d.photoUrl!) : null,
                                    child: d.photoUrl == null ? const Icon(Icons.person) : null,
                                  ),
                                  title: Text(d.fullName),
                                  subtitle: Text('${d.specialty} · ${d.qualification}'),
                                  trailing: Text('₹${d.consultationFee.toStringAsFixed(0)}'),
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: d, facility: facility))),
                                ),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorRetryView(message: 'Could not load doctors', onRetry: () => ref.invalidate(facilityDoctorsProvider(facilityId))),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.tokens.text3),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
