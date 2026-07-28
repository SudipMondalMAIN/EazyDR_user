import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/location/location_provider.dart';
import '../../core/models/facility.dart';
import '../../core/repositories/facilities_repository.dart';
import '../../core/repositories/misc_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/login_screen.dart';
import '../location/location_picker_screen.dart';
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

const _navy = Color(0xFF163A73);
const _teal = Color(0xFF1AA391);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeBannersProvider);
            ref.invalidate(facilitySearchProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              _TopBar(location: location),
              const SizedBox(height: 20),
              const _HeroBanner(),
              const SizedBox(height: 20),
              const _SearchBar(),
              if (auth.status == SessionStatus.loggedOut) ...[
                const SizedBox(height: 16),
                _SignedOutCta(),
              ],
              const SizedBox(height: 20),
              _CategoryRow(),
              const SizedBox(height: 16),
              const _PromoBanner(),
              const SizedBox(height: 16),
              const _OffersCarousel(),
              SectionHeader(
                title: location.valueOrNull?.isGps == true
                    ? 'Near you'
                    : 'In ${location.valueOrNull?.city ?? "your city"}',
                onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              const SizedBox(height: 4),
              const SectionHeader(title: 'Popular specialisations'),
              _SpecialisationChips(),
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Nearby Facilities',
                onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              _NearYouList(location: location),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final AsyncValue<AppLocation> location;
  const _TopBar({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(kRadiusSm),
            onTap: () => _showCityPicker(context, ref),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
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
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen())),
            ),
            if ((unread.valueOrNull ?? 0) > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ],
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_rounded),
              label: const Text('Choose on map'),
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LocationPickerScreen(),
                ));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Logo + tagline on the left, a soft illustrated doctor mark on the right —
/// mirrors the reference home header (no photo asset available, so the
/// illustration is built from vector shapes/icons in the brand colours).
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(text: 'Eazy', style: TextStyle(color: _navy)),
                    TextSpan(text: 'Doctor', style: TextStyle(color: _teal)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('Your health, our priority',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.tokens.text3)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _DoctorMark(),
      ],
    );
  }
}

class _DoctorMark extends StatelessWidget {
  const _DoctorMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: _teal.withOpacity(0.12), shape: BoxShape.circle),
          ),
          Positioned(
            left: 4,
            bottom: 10,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: _teal.withOpacity(0.18), shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, size: 16, color: _teal),
            ),
          ),
          Positioned(
            right: 0,
            top: 6,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: _teal.withOpacity(0.18), shape: BoxShape.circle),
              child: Icon(Icons.favorite_rounded, size: 16, color: _teal),
            ),
          ),
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child:
                Icon(Icons.medical_information_rounded, size: 44, color: _navy),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.tokens.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: context.tokens.text3),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Search doctor, disease, specialty or area',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.tokens.text3)),
            ),
          ],
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
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
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
    (
      FacilityType.doctorChamber,
      Icons.medical_services_rounded,
      'Doctors',
      _teal
    ),
    (
      FacilityType.nursingHome,
      Icons.local_hospital_rounded,
      'Nursing Homes',
      Color(0xFFDC2626)
    ),
    (
      FacilityType.pharmacy,
      Icons.medication_rounded,
      'Pharmacies',
      Color(0xFF16A34A)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        ..._cats.map((c) => _CategoryItem(
              icon: c.$2,
              label: c.$3,
              color: c.$4,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SearchScreen(initialType: c.$1))),
            )),
        _CategoryItem(
          icon: Icons.science_rounded,
          label: 'Labs',
          color: const Color(0xFF2563EB),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SearchScreen(initialQuery: 'Lab'))),
        ),
        _CategoryItem(
          icon: Icons.grid_view_rounded,
          label: 'More',
          color: tokens.text2,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CategoryItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.tokens.surface2,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(kRadius),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.tokens.successSoft,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kRadiusSm)),
              child: Icon(Icons.calendar_month_rounded,
                  color: context.tokens.successColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book Appointments Easily',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: context.tokens.successColor)),
                  const SizedBox(height: 2),
                  Text('Quick booking • Live queue • Secure payment',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: context.tokens.successColor, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
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

/// "Health Check-up Packages" style promo carousel — uses the backend's
/// active banners when available, and falls back to a static promo card
/// (matching the reference design) when there are none yet.
class _OffersCarousel extends ConsumerStatefulWidget {
  const _OffersCarousel();

  @override
  ConsumerState<_OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends ConsumerState<_OffersCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(activeBannersProvider);
    final theme = Theme.of(context);

    return banners.when(
      loading: () => const SizedBox(height: 150, child: LoadingView()),
      error: (_, __) => _buildFallback(context),
      data: (list) {
        if (list.isEmpty) return _buildFallback(context);
        return Column(
          children: [
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _controller,
                itemCount: list.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final b = list[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kRadiusLg),
                      child: b.imageUrl != null
                          ? Image.network(b.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _bannerFallback(context, b.title))
                          : _bannerFallback(context, b.title),
                    ),
                  );
                },
              ),
            ),
            if (list.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  list.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : context.tokens.surface2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _bannerFallback(BuildContext context, String title) => Container(
        color: context.tokens.surface2,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(title, textAlign: TextAlign.center),
      );

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.tokens.successSoft,
            context.tokens.successColor.withOpacity(0.25)
          ],
        ),
        borderRadius: BorderRadius.circular(kRadiusLg),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Health Check-up\nPackages',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: _navy, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Stay healthy, stay happy',
                  style: theme.textTheme.bodySmall),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
                child: const Text('Book Now'),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('UP TO', style: theme.textTheme.labelSmall),
                  Text('30%',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: context.tokens.successColor,
                          fontWeight: FontWeight.w800)),
                  Text('OFF', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
                    child: _NearbyFacilityTile(
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

/// Facility row matching the reference "Nearby Facilities" list: thumbnail,
/// name, type, distance • city, star rating, and an Open/Closed dot.
class _NearbyFacilityTile extends ConsumerWidget {
  final Facility facility;
  final VoidCallback onTap;
  const _NearbyFacilityTile({required this.facility, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final rating = ref.watch(facilityRatingSummaryProvider(facility.id));

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
                    ? Image.network(facility.photoUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(tokens))
                    : Container(
                        width: 64,
                        height: 64,
                        color: tokens.surface2,
                        child: _placeholder(tokens)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(facilityTypeLabel(facility.facilityType),
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: tokens.text3),
                        const SizedBox(width: 2),
                        Text(
                          [
                            if (facility.distanceKm != null)
                              '${facility.distanceKm!.toStringAsFixed(1)} km',
                            facility.city,
                          ].join(' • '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        rating.when(
                          data: (r) => Text(
                            r.averageRating != null
                                ? '${r.averageRating!.toStringAsFixed(1)} (${r.totalReviews})'
                                : 'New',
                            style: theme.textTheme.bodySmall,
                          ),
                          loading: () => const SizedBox(width: 30, height: 12),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 10),
                        Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: tokens.successColor,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(facility.isActive ? 'Open' : 'Closed',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: facility.isActive
                                    ? tokens.successColor
                                    : tokens.dangerColor)),
                      ],
                    ),
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

  Widget _placeholder(AppColorTokens tokens) {
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
