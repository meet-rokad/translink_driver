// user_profile.dart — Rewritten to remove cloud_firestore dependency.
// Uses plain Dart DateTime (timestamps stored as ISO8601 strings in Supabase).

class UserProfile {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final String city;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.city,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? map['id'] ?? '',
      fullName: map['fullName'] ?? map['full_name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['mobile_number'] ?? '',
      city: map['city'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? map['profile_photo_url'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : map['updated_at'] != null
              ? DateTime.parse(map['updated_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'city': city,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
