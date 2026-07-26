import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/misc_models.dart';

// ---------------- Favorites ----------------
class FavoritesRepository {
  final Ref ref;
  FavoritesRepository(this.ref);

  Future<List<Favorite>> mine() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/favorites/me');
    return (res.data as List).map((e) => Favorite.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Favorite> add(FavoriteTargetType type, String targetId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/favorites', data: {'target_type': favTargetToApi(type), 'target_id': targetId});
    return Favorite.fromJson(res.data);
  }

  Future<void> remove(String favoriteId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/api/v1/favorites/$favoriteId');
  }
}

final favoritesRepositoryProvider = Provider((ref) => FavoritesRepository(ref));
final myFavoritesProvider = FutureProvider<List<Favorite>>((ref) => ref.read(favoritesRepositoryProvider).mine());

// ---------------- Reviews ----------------
class ReviewsRepository {
  final Ref ref;
  ReviewsRepository(this.ref);

  Future<RatingSummary> doctorSummary(String doctorId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/reviews/doctor/$doctorId/summary');
    return RatingSummary.fromJson(res.data);
  }

  Future<List<Review>> doctorReviews(String doctorId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/reviews/doctor/$doctorId');
    return (res.data as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RatingSummary> facilitySummary(String facilityId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/reviews/facility/$facilityId/summary');
    return RatingSummary.fromJson(res.data);
  }

  Future<Review> submit({required String bookingId, required int rating, String? comment}) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/reviews', data: {'booking_id': bookingId, 'rating': rating, 'comment': comment});
    return Review.fromJson(res.data);
  }
}

final reviewsRepositoryProvider = Provider((ref) => ReviewsRepository(ref));
final doctorRatingSummaryProvider = FutureProvider.family<RatingSummary, String>((ref, doctorId) => ref.read(reviewsRepositoryProvider).doctorSummary(doctorId));
final doctorReviewsProvider = FutureProvider.family<List<Review>, String>((ref, doctorId) => ref.read(reviewsRepositoryProvider).doctorReviews(doctorId));
final facilityRatingSummaryProvider = FutureProvider.family<RatingSummary, String>((ref, facilityId) => ref.read(reviewsRepositoryProvider).facilitySummary(facilityId));

// ---------------- Notifications ----------------
class NotificationsRepository {
  final Ref ref;
  NotificationsRepository(this.ref);

  Future<List<AppNotification>> mine() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/notifications/me');
    return (res.data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/notifications/me/unread-count');
    return res.data['unread_count'] ?? 0;
  }

  Future<void> markRead(String id) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/api/v1/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/notifications/read-all');
  }
}

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref));
final myNotificationsProvider = FutureProvider<List<AppNotification>>((ref) => ref.read(notificationsRepositoryProvider).mine());
final unreadCountProvider = FutureProvider<int>((ref) => ref.read(notificationsRepositoryProvider).unreadCount());

// ---------------- Banners ----------------
class BannersRepository {
  final Ref ref;
  BannersRepository(this.ref);

  Future<List<AppBanner>> active() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/banners', query: {'active_only': true});
    final list = (res.data as List).map((e) => AppBanner.fromJson(e as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }
}

final bannersRepositoryProvider = Provider((ref) => BannersRepository(ref));
final activeBannersProvider = FutureProvider<List<AppBanner>>((ref) => ref.read(bannersRepositoryProvider).active());

// ---------------- Rewards (patient wallet) ----------------
class RewardsRepository {
  final Ref ref;
  RewardsRepository(this.ref);

  Future<int> balance() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/rewards/balance');
    return res.data['points'] ?? 0;
  }
}

final rewardsRepositoryProvider = Provider((ref) => RewardsRepository(ref));
final rewardBalanceProvider = FutureProvider<int>((ref) => ref.read(rewardsRepositoryProvider).balance());
