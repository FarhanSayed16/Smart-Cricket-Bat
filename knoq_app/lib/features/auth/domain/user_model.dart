class UserModel {
  final String id;
  final String firebaseUid;
  final String? name;
  final String email;
  final String role;
  final String? academyId;
  final String? battingHand;
  final int? age;
  final String? assignedCoachId;
  final String? profileImageUrl;
  final String? fcmToken;
  final String? appVersion;
  final bool onboardingComplete;
  final bool isAcademyOwner;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? deletionRequestedAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    this.name,
    required this.email,
    required this.role,
    this.academyId,
    this.battingHand,
    this.age,
    this.assignedCoachId,
    this.profileImageUrl,
    this.fcmToken,
    this.appVersion,
    this.onboardingComplete = false,
    this.isAcademyOwner = false,
    this.createdAt,
    this.lastLoginAt,
    this.deletionRequestedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
      academyId: json['academy_id'] as String?,
      battingHand: json['batting_hand'] as String?,
      age: json['age'] as int?,
      assignedCoachId: json['assigned_coach_id'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      fcmToken: json['fcm_token'] as String?,
      appVersion: json['app_version'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      isAcademyOwner: json['is_academy_owner'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      lastLoginAt: json['last_login_at'] != null ? DateTime.parse(json['last_login_at']) : null,
      deletionRequestedAt: json['deletion_requested_at'] != null ? DateTime.parse(json['deletion_requested_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'name': name,
      'email': email,
      'role': role,
      'academy_id': academyId,
      'batting_hand': battingHand,
      'age': age,
      'assigned_coach_id': assignedCoachId,
      'profile_image_url': profileImageUrl,
      'fcm_token': fcmToken,
      'app_version': appVersion,
      'onboarding_complete': onboardingComplete,
      'is_academy_owner': isAcademyOwner,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'deletion_requested_at': deletionRequestedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? firebaseUid,
    String? name,
    String? email,
    String? role,
    String? academyId,
    String? battingHand,
    int? age,
    String? assignedCoachId,
    bool? onboardingComplete,
    bool? isAcademyOwner,
    String? profileImageUrl,
    String? fcmToken,
    String? appVersion,
    DateTime? lastLoginAt,
    DateTime? deletionRequestedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      battingHand: battingHand ?? this.battingHand,
      age: age ?? this.age,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      isAcademyOwner: isAcademyOwner ?? this.isAcademyOwner,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      academyId: academyId ?? this.academyId,
      assignedCoachId: assignedCoachId ?? this.assignedCoachId,
      fcmToken: fcmToken ?? this.fcmToken,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
    );
  }
}
