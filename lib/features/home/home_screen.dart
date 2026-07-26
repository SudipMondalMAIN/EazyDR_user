import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/location/location_provider.dart';
import '../../core/models/facility.dart';
import '../../core/repositories/facilities_repository.dart';
import '../../core/repositories/misc_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_screen.dart';
import '../facility_detail/facility_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';

const _specialisations = [
  'General Physician',
  'Pediatrics',
  'Gynaecology',
  'Orthopedics',
  'Dermatology',
  'Cardiology',
  'ENT',
  'Dentist'
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EazyDoctor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBannersProvider);
          ref.invalidate(facilitySearchProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            _LocationBar(location: location),
            const SizedBox(height: 16),
            _HeroSearchCard(),
            if (auth.status == SessionStatus.loggedOut) ...[
              const SizedBox(height: 16),
              _SignedOutCta(),
            ],
            const SectionHeader(title: 'Book by category'),
            _CategoryRow(),
            const SectionHeader(title: 'Popular specialisations'),
            _SpecialisationChips(),
            const SectionHeader(title: 'Offers & updates'),
            _BannersCarousel(),
            SectionHeader(
                title: location.valueOrNull?.isGps == true
                    ? 'Near you'
                    : 'In ${location.valueOrNull?.city ?? "your city"}'),
            _NearYouList(location: location),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LocationBar extends ConsumerWidget {
  final AsyncValue<AppLocation> location;
  const _LocationBar({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(kRadiusSm),
      onTap: () => _showCityPicker(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: location.when(
                data: (loc) => Text(loc.city,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis),
                loading: () => const Text('Detecting location…'),
                error: (_, __) => const Text('Set your location'),
              ),
            ),
            Icon(Icons.expand_more_rounded,
                size: 18, color: context.tokens.text3),
          ],
        ),
      ),
    );
  }

  void _showCityPicker(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: location.valueOrNull?.city ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose your city', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: 'City name')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Use GPS'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(locationProvider.notifier).redetect();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isNotEmpty) {
                      ref
                          .read(locationProvider.notifier)
                          .setManualCity(ctrl.text.trim());
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HeroSearchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good day 👋',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Find doctors, pharmacies & nursing homes near you',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.search, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedOutCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.tokens.primarySoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log in to book appointments',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Track tokens, earn rewards and save your favourites.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _cats = const [
    (FacilityType.doctorChamber, Icons.medical_services_rounded, 'Doctors'),
    (FacilityType.pharmacy, Icons.local_pharmacy_rounded, 'Pharmacies'),
    (FacilityType.nursingHome, Icons.local_hospital_rounded, 'Nursing Homes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _cats
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(kRadius),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SearchScreen(initialType: c.$1))),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(children: [
                          Icon(c.$2,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(c.$3,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SpecialisationChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _specialisations
          .map((s) => ActionChip(
                label: Text(s),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SearchScreen(initialQuery: s))),
              ))
          .toList(),
    );
  }
}

class _BannersCarousel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(activeBannersProvider);
    return banners.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final b = list[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: SizedBox(
                  width: 260,
                  child: b.imageUrl != null
                      ? Image.network(b.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _bannerFallback(context, b.title))
                      : _bannerFallback(context, b.title),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 120, child: LoadingView()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _bannerFallback(BuildContext context, String title) => Container(
        color: context.tokens.surface2,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(title, textAlign: TextAlign.center),
      );
}

class _NearYouList extends ConsumerWidget {
  final AsyncValue<AppLocation> location;
  const _NearYouList({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = location.valueOrNull;
    if (loc == null) {
      if (location.hasError) {
        return ErrorRetryView(
          message: 'Could not detect location',
          onRetry: () => ref.read(locationProvider.notifier).redetect(),
        );
      }
      return const LoadingView();
    }
    final params = FacilitySearchParams(
        latitude: loc.latitude,
        longitude: loc.longitude,
        city: loc.latitude == null ? loc.city : null,
        radiusKm: 10);
    final facilities = ref.watch(facilitySearchProvider(params));
    return facilities.when(
      data: (list) {
        if (list.isEmpty)
          return const EmptyView(message: 'No facilities found nearby yet.');
        return Column(
          children: list
              .take(8)
              .map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FacilityCard(
                      facility: f,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              FacilityDetailScreen(facilityId: f.id))),
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const LoadingView(),
      error: (e, _) => ErrorRetryView(
          message: 'Could not load nearby facilities',
          onRetry: () => ref.invalidate(facilitySearchProvider(params))),
    );
  }
}
