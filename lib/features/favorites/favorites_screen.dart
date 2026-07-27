import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/misc_models.dart';
import '../../core/repositories/misc_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/login_screen.dart';
import '../facility_detail/facility_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.status == SessionStatus.loggedOut) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border_rounded,
                    size: 40, color: context.tokens.text3),
                const SizedBox(height: 12),
                Text('Log in to save your favorites',
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

    final favoritesAsync = ref.watch(myFavoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(
            message: 'Could not load favorites',
            onRetry: () => ref.invalidate(myFavoritesProvider)),
        data: (favorites) {
          if (favorites.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myFavoritesProvider),
              child: ListView(children: const [
                EmptyView(
                    message:
                        'Doctors and facilities you save will show up here.',
                    icon: Icons.favorite_border_rounded),
              ]),
            );
          }
          final doctors = favorites
              .where((f) => f.targetType == FavoriteTargetType.doctor)
              .toList();
          final facilities = favorites
              .where((f) => f.targetType == FavoriteTargetType.facility)
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myFavoritesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (facilities.isNotEmpty) ...[
                  const SectionHeader(title: 'Facilities'),
                  ...facilities.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FavoriteCard(favorite: f, ref: ref),
                      )),
                ],
                if (doctors.isNotEmpty) ...[
                  const SectionHeader(title: 'Doctors'),
                  ...doctors.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FavoriteCard(favorite: f, ref: ref),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Favorite favorite;
  final WidgetRef ref;
  const _FavoriteCard({required this.favorite, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isFacility = favorite.targetType == FavoriteTargetType.facility;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: () {
          if (isFacility) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    FacilityDetailScreen(facilityId: favorite.targetId)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Open the facility this doctor practices at to view their profile.')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.tokens.surface2,
                child: Icon(
                  isFacility
                      ? Icons.local_hospital_outlined
                      : Icons.medical_services_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(favorite.name ?? (isFacility ? 'Facility' : 'Doctor'),
                        style: Theme.of(context).textTheme.titleMedium),
                    if (favorite.subtitle != null &&
                        favorite.subtitle!.isNotEmpty)
                      Text(favorite.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: context.tokens.dangerColor),
                onPressed: () async {
                  try {
                    await ref
                        .read(favoritesRepositoryProvider)
                        .remove(favorite.id);
                    ref.invalidate(myFavoritesProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not remove: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
