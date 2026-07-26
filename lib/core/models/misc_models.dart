// ---------------- Favorites ----------------
enum FavoriteTargetType { doctor, facility }

FavoriteTargetType favTargetFromApi(String v) => v == 'facility' ? FavoriteTargetType.facility : FavoriteTargetType.doctor;
String favTargetToApi(FavoriteTargetType t) => t == FavoriteTargetType.facility ? 'facility' : 'doctor';

class Favorite {
  final String id;
  final FavoriteTargetType targetType;
  final String targetId;
  final String? name;
  final String? subtitle;

  Favorite({required this.id, required this.targetType, required this.targetId, this.name, this.subtitle});

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['id'].toString(),
        targetType: favTargetFromApi(json['target_type']),
        targetId: json['target_id'].toString(),
        name: json['name'],
        subtitle: json['subtitle'],
      );
}

// ---------------- Reviews ----------------
class Review {
  final String id;
  final String bookingId;
  final String doctorId;
  final String facilityId;
  final int rating;
  final String? comment;

  Review({required this.id, required this.bookingId, required this.doctorId, required this.facilityId, required this.rating, this.comment});

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'].toString(),
        bookingId: json['booking_id'].toString(),
        doctorId: json['doctor_id'].toString(),
        facilityId: json['facility_id'].toString(),
        rating: json['rating'] ?? 0,
        comment: json['comment'],
      );
}

class RatingSummary {
  final double? averageRating;
  final int totalReviews;
  RatingSummary({this.averageRating, required this.totalReviews});
  factory RatingSummary.fromJson(Map<String, dynamic> json) => RatingSummary(
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        totalReviews: json['total_reviews'] ?? 0,
      );
}

// ---------------- Notifications ----------------
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? relatedBookingId;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedBookingId,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        type: json['notification_type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        relatedBookingId: json['related_booking_id']?.toString(),
        isRead: json['is_read'] ?? false,
      );
}

// ---------------- Banners ----------------
class AppBanner {
  final String id;
  final String title;
  final String? imageUrl;
  final String? redirectUrl;
  final int displayOrder;

  AppBanner({required this.id, required this.title, this.imageUrl, this.redirectUrl, required this.displayOrder});

  factory AppBanner.fromJson(Map<String, dynamic> json) => AppBanner(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        imageUrl: json['image_url'],
        redirectUrl: json['redirect_url'],
        displayOrder: json['display_order'] ?? 0,
      );
}
