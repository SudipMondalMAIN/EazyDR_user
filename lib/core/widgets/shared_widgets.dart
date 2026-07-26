import 'package:flutter/material.dart';
import '../models/facility.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  const StatusPill({super.key, required this.label, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 40, color: tokens.text3),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: tokens.text2), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetryView({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: context.tokens.text3),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.tokens.text2)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class FacilityCard extends StatelessWidget {
  final Facility facility;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const FacilityCard({
    super.key,
    required this.facility,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(kRadiusSm),
                child: facility.photoUrl != null
                    ? Image.network(facility.photoUrl!, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon(tokens))
                    : Container(width: 64, height: 64, color: tokens.surface2, child: _placeholderIcon(tokens)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(facility.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (onFavoriteToggle != null)
                          InkWell(
                            onTap: onFavoriteToggle,
                            child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 20, color: isFavorite ? tokens.dangerColor : tokens.text3),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (facility.isVerified) StatusPill(label: 'Verified', color: tokens.successColor, background: tokens.successSoft),
                      if (facility.isAdSponsored) StatusPill(label: 'Sponsored', color: tokens.accentColor, background: tokens.accentSoft),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      [
                        facility.city,
                        if (facility.distanceKm != null) '${facility.distanceKm!.toStringAsFixed(1)} km away',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Booking fee ₹${facility.bookingFee.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(AppColorTokens tokens) {
    IconData icon;
    switch (facility.facilityType) {
      case FacilityType.pharmacy:
        icon = Icons.local_pharmacy_outlined;
        break;
      case FacilityType.nursingHome:
        icon = Icons.local_hospital_outlined;
        break;
      case FacilityType.doctorChamber:
        icon = Icons.medical_services_outlined;
        break;
    }
    return Icon(icon, color: tokens.text3);
  }
}
