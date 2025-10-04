/// Player profile model for Coach's Eye AI app
/// Represents a player's profile with coach relationship
class PlayerProfile {
  final String uid;
  final String displayName;
  final String? coachId; // Nullable - player might not have a coach yet

  const PlayerProfile({
    required this.uid,
    required this.displayName,
    this.coachId,
  });

  /// Create PlayerProfile from Firestore document
  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      coachId: json['coachId'] as String?,
    );
  }

  /// Convert PlayerProfile to Firestore document
  Map<String, dynamic> toJson() {
    return {'uid': uid, 'displayName': displayName, 'coachId': coachId};
  }

  /// Create a copy of PlayerProfile with updated fields
  PlayerProfile copyWith({String? uid, String? displayName, String? coachId}) {
    return PlayerProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      coachId: coachId ?? this.coachId,
    );
  }

  @override
  String toString() {
    return 'PlayerProfile(uid: $uid, displayName: $displayName, coachId: $coachId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerProfile &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.coachId == coachId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ displayName.hashCode ^ coachId.hashCode;
  }
}

/// Coach profile model for Coach's Eye AI app
/// Represents a coach's profile with linked players
class CoachProfile {
  final String uid;
  final String displayName;
  final List<String> playerIds; // List of player UIDs linked to this coach
  final String? inviteCode; // Unique invite code for players to join

  const CoachProfile({
    required this.uid,
    required this.displayName,
    this.playerIds = const [],
    this.inviteCode,
  });

  /// Create CoachProfile from Firestore document
  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      playerIds: List<String>.from(json['playerIds'] ?? []),
      inviteCode: json['inviteCode'] as String?,
    );
  }

  /// Convert CoachProfile to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'playerIds': playerIds,
      'inviteCode': inviteCode,
    };
  }

  /// Create a copy of CoachProfile with updated fields
  CoachProfile copyWith({
    String? uid,
    String? displayName,
    List<String>? playerIds,
    String? inviteCode,
  }) {
    return CoachProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      playerIds: playerIds ?? this.playerIds,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }

  /// Add a player to the coach's player list
  CoachProfile addPlayer(String playerId) {
    if (playerIds.contains(playerId)) return this;
    return copyWith(playerIds: [...playerIds, playerId]);
  }

  /// Remove a player from the coach's player list
  CoachProfile removePlayer(String playerId) {
    return copyWith(
      playerIds: playerIds.where((id) => id != playerId).toList(),
    );
  }

  @override
  String toString() {
    return 'CoachProfile(uid: $uid, displayName: $displayName, playerIds: $playerIds, inviteCode: $inviteCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachProfile &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.playerIds.length == playerIds.length &&
        other.playerIds.every((id) => playerIds.contains(id)) &&
        other.inviteCode == inviteCode;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        displayName.hashCode ^
        playerIds.hashCode ^
        inviteCode.hashCode;
  }
}

/// Coach invite code model for tracking invite codes
class CoachInviteCode {
  final String code;
  final String coachId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  const CoachInviteCode({
    required this.code,
    required this.coachId,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
  });

  /// Create CoachInviteCode from Firestore document
  factory CoachInviteCode.fromJson(Map<String, dynamic> json) {
    return CoachInviteCode(
      code: json['code'] as String,
      coachId: json['coachId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert CoachInviteCode to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'coachId': coachId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  /// Check if the invite code is still valid
  bool get isValid {
    return isActive && DateTime.now().isBefore(expiresAt);
  }

  @override
  String toString() {
    return 'CoachInviteCode(code: $code, coachId: $coachId, createdAt: $createdAt, expiresAt: $expiresAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachInviteCode &&
        other.code == code &&
        other.coachId == coachId &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        coachId.hashCode ^
        createdAt.hashCode ^
        expiresAt.hashCode ^
        isActive.hashCode;
  }
}

