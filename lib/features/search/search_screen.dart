import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/location/location_provider.dart';
import '../../core/models/facility.dart';
import '../../core/repositories/facilities_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../facility_detail/facility_detail_screen.dart';

const List<double> _radiusPresets = [5, 10, 25, 50, 100, 200];

IconData _iconForType(FacilityType t) {
  switch (t) {
    case FacilityType.nursingHome:
      return Icons.local_hospital_rounded;
    case FacilityType.pharmacy:
      return Icons.medication_rounded;
    case FacilityType.doctorChamber:
      return Icons.medical_services_rounded;
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  final FacilityType? initialType;
  final String? initialQuery;
  const SearchScreen({super.key, this.initialType, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryCtrl =
      TextEditingController(text: widget.initialQuery ?? '');
  late final TextEditingController _cityCtrl = TextEditingController();
  bool _nearMe = true;
  double _radius = 10;
  FacilityType? _type;
  String _debouncedQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _debouncedQuery = widget.initialQuery?.trim() ?? '';
    _queryCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.removeListener(_onQueryChanged);
    _queryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = _queryCtrl.text.trim());
    });
  }

  bool get _hasActiveFilters =>
      _type != null || (!_nearMe && _cityCtrl.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final location = ref.watch(locationProvider);
    if (_nearMe && _cityCtrl.text.isEmpty) {
      _cityCtrl.text = location.valueOrNull?.city ?? '';
    }

    final params = FacilitySearchParams(
      query: _debouncedQuery.isEmpty ? null : _debouncedQuery,
      latitude: _nearMe ? location.valueOrNull?.latitude : null,
      longitude: _nearMe ? location.valueOrNull?.longitude : null,
      city: _nearMe
          ? null
          : (_cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim()),
      radiusKm: _radius,
      facilityType: _type,
    );
    final results = ref.watch(facilitySearchProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _queryCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Doctor, disease, specialty or area',
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _queryCtrl,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _queryCtrl.clear();
                            _debounce?.cancel();
                            setState(() => _debouncedQuery = '');
                          },
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text('Near me'),
                  selected: _nearMe,
                  onSelected: (v) => setState(() => _nearMe = v),
                ),
                const SizedBox(width: 8),
                if (!_nearMe)
                  Expanded(
                    child: TextField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter a city',
                        isDense: true,
                        prefixIcon: Icon(Icons.location_city_rounded, size: 18),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  )
                else
                  Expanded(child: _LocationStatus(location: location)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                const SizedBox(width: 8),
                ...FacilityType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(_iconForType(t), size: 16),
                        label: Text(facilityTypeLabel(t)),
                        selected: _type == t,
                        onSelected: (_) =>
                            setState(() => _type = _type == t ? null : t),
                      ),
                    )),
              ],
            ),
          ),
          if (_nearMe) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.social_distance_rounded,
                      size: 18, color: tokens.text3),
                  const SizedBox(width: 6),
                  const Text('Radius'),
                  const Spacer(),
                  Text('${_radius.round()} km',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Slider(
                value: _radius,
                min: 1,
                max: 200,
                divisions: 199,
                label: '${_radius.round()} km',
                onChanged: (v) => setState(() => _radius = v),
              ),
            ),
            SizedBox(
              height: 32,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _radiusPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final r = _radiusPresets[i];
                  final selected = _radius.round() == r.round();
                  return GestureDetector(
                    onTap: () => setState(() => _radius = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : tokens.primarySoft,
                        borderRadius: BorderRadius.circular(kRadiusSm),
                      ),
                      child: Text(
                        '${r.round()} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
          const Divider(height: 17),
          Expanded(
            child: results.when(
              data: (list) {
                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(facilitySearchProvider(params)),
                    child: ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyView(
                          message: _debouncedQuery.isNotEmpty ||
                                  _hasActiveFilters
                              ? 'No results for these filters. Try a wider radius or fewer filters.'
                              : 'No facilities found nearby. Try widening your search.',
                          icon: Icons.search_off_rounded,
                        ),
                        if (_nearMe && _radius < 200) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => _radius = 200),
                              child: const Text('Search within 200 km instead'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(facilitySearchProvider(params)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${list.length} result${list.length == 1 ? '' : 's'} found',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: tokens.text3),
                          ),
                        );
                      }
                      final facility = list[i - 1];
                      return FacilityCard(
                        facility: facility,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => FacilityDetailScreen(
                                  facilityId: facility.id)),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => ErrorRetryView(
                message: 'Search failed',
                onRetry: () => ref.invalidate(facilitySearchProvider(params)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationStatus extends StatelessWidget {
  final AsyncValue<AppLocation> location;
  const _LocationStatus({required this.location});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return location.when(
      loading: () => Row(
        children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: tokens.text3)),
          const SizedBox(width: 8),
          Text('Locating you…',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.text3)),
        ],
      ),
      error: (_, __) => Row(
        children: [
          Icon(Icons.location_off_rounded, size: 16, color: tokens.dangerColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Location unavailable — enable it or search by city',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.dangerColor),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      data: (loc) => Row(
        children: [
          Icon(Icons.place_rounded, size: 16, color: tokens.text3),
          const SizedBox(width: 4),
          Expanded(
            child: Text(loc.city.isNotEmpty ? loc.city : 'Current location',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
