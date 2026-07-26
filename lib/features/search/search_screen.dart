import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/location/location_provider.dart';
import '../../core/models/facility.dart';
import '../../core/repositories/facilities_repository.dart';
import '../../core/widgets/shared_widgets.dart';
import '../facility_detail/facility_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final FacilityType? initialType;
  final String? initialQuery;
  const SearchScreen({super.key, this.initialType, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryCtrl = TextEditingController(text: widget.initialQuery ?? '');
  late final TextEditingController _cityCtrl = TextEditingController();
  bool _nearMe = true;
  double _radius = 10;
  FacilityType? _type;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    if (_nearMe && _cityCtrl.text.isEmpty) {
      _cityCtrl.text = location.valueOrNull?.city ?? '';
    }

    final params = FacilitySearchParams(
      query: _queryCtrl.text.trim().isEmpty ? null : _queryCtrl.text.trim(),
      latitude: _nearMe ? location.valueOrNull?.latitude : null,
      longitude: _nearMe ? location.valueOrNull?.longitude : null,
      city: _nearMe ? null : (_cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim()),
      radiusKm: _radius,
      facilityType: _type,
    );
    final results = ref.watch(facilitySearchProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _queryCtrl,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Doctor, disease, specialty or area'),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Near me'),
                  selected: _nearMe,
                  onSelected: (v) => setState(() => _nearMe = v),
                ),
                const SizedBox(width: 8),
                if (!_nearMe)
                  Expanded(
                    child: TextField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(hintText: 'City', isDense: true),
                      onSubmitted: (_) => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(label: const Text('All'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
                  const SizedBox(width: 8),
                  ...FacilityType.values.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(facilityTypeLabel(t)),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = _type == t ? null : t),
                        ),
                      )),
                ],
              ),
            ),
          ),
          if (_nearMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Radius'),
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '${_radius.round()} km',
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ),
                  Text('${_radius.round()} km'),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: results.when(
              data: (list) {
                if (list.isEmpty) return const EmptyView(message: 'No results. Try widening your search.');
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => FacilityCard(
                    facility: list[i],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FacilityDetailScreen(facilityId: list[i].id))),
                  ),
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => ErrorRetryView(message: 'Search failed', onRetry: () => ref.invalidate(facilitySearchProvider(params))),
            ),
          ),
        ],
      ),
    );
  }
}
