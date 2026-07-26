class AppUser {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final bool isActive;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isPhoneVerified,
    required this.isEmailVerified,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        fullName: json['full_name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'patient',
        isActive: json['is_active'] ?? true,
        isPhoneVerified: json['is_phone_verified'] ?? false,
        isEmailVerified: json['is_email_verified'] ?? false,
        photoUrl: json['photo_url'],
      );
}
