import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/shot_model.dart';
import '../models/profile_models.dart';

/// Service class for Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new user profile in Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Get user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Start a new practice session
  Future<String> startNewSession(String playerId) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = SessionModel(
        sessionId: sessionId,
        playerId: playerId,
        date: DateTime.now(),
        durationInMinutes: 0,
        totalShots: 0,
        averageBatSpeed: 0.0,
      );

      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .set(session.toJson());

      return sessionId;
    } catch (e) {
      throw Exception('Failed to start new session: $e');
    }
  }

  /// Add a shot to an existing session
  Future<void> addShotToSession(ShotModel shot) async {
    try {
      await _firestore.collection('shots').doc(shot.shotId).set(shot.toJson());
    } catch (e) {
      throw Exception('Failed to add shot to session: $e');
    }
  }

  /// End a session and update session statistics
  Future<void> endSession(String sessionId, List<ShotModel> shots) async {
    try {
      if (shots.isEmpty) {
        throw Exception('No shots found for session');
      }

      // Calculate session statistics
      final totalShots = shots.length;
      final averageBatSpeed =
          shots.map((shot) => shot.batSpeed).reduce((a, b) => a + b) /
          totalShots;

      final sessionStartTime = shots.first.timestamp;
      final sessionEndTime = shots.last.timestamp;
      final durationInMinutes = sessionEndTime
          .difference(sessionStartTime)
          .inMinutes;

      // Update session document
      await _firestore.collection('sessions').doc(sessionId).update({
        'totalShots': totalShots,
        'averageBatSpeed': averageBatSpeed,
        'durationInMinutes': durationInMinutes,
      });
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  /// Get all sessions for a specific player
  Future<List<SessionModel>> getSessionsForPlayer(String playerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('playerId', isEqualTo: playerId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SessionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sessions for player: $e');
    }
  }

  /// Get all shots for a specific session
  Future<List<ShotModel>> getShotsForSession(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('shots')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ShotModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get shots for session: $e');
    }
  }

  /// Stream of sessions for a specific player
  Stream<List<SessionModel>> getSessionsStream(String playerId) {
    return _firestore
        .collection('sessions')
        .where('playerId', isEqualTo: playerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SessionModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Stream of shots for a specific session
  Stream<List<ShotModel>> getShotsStream(String sessionId) {
    return _firestore
        .collection('shots')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShotModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Delete a session and all its shots
  Future<void> deleteSession(String sessionId) async {
    try {
      // Delete all shots for this session
      final shotsSnapshot = await _firestore
          .collection('shots')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      final batch = _firestore.batch();
      for (final doc in shotsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the session document
      batch.delete(_firestore.collection('sessions').doc(sessionId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // ===== COACH-PLAYER RELATIONSHIP METHODS =====

  /// Create a player profile
  Future<void> createPlayerProfile(PlayerProfile player) async {
    try {
      await _firestore
          .collection('playerProfiles')
          .doc(player.uid)
          .set(player.toJson());
    } catch (e) {
      throw Exception('Failed to create player profile: $e');
    }
  }

  /// Create a coach profile
  Future<void> createCoachProfile(CoachProfile coach) async {
    try {
      await _firestore
          .collection('coachProfiles')
          .doc(coach.uid)
          .set(coach.toJson());
    } catch (e) {
      throw Exception('Failed to create coach profile: $e');
    }
  }

  /// Get player profile by UID
  Future<PlayerProfile?> getPlayerProfile(String uid) async {
    try {
      final doc = await _firestore.collection('playerProfiles').doc(uid).get();

      if (doc.exists) {
        return PlayerProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get player profile: $e');
    }
  }

  /// Get coach profile by UID
  Future<CoachProfile?> getCoachProfile(String uid) async {
    try {
      final doc = await _firestore.collection('coachProfiles').doc(uid).get();

      if (doc.exists) {
        return CoachProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get coach profile: $e');
    }
  }

  /// Generate a unique coach invite code
  Future<String> generateCoachInviteCode({required String coachId}) async {
    try {
      // Generate a 6-character alphanumeric code
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = DateTime.now().millisecondsSinceEpoch;
      final code = String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(random % chars.length)),
      );

      // Check if code already exists
      final existingCode = await _firestore
          .collection('coachInviteCodes')
          .doc(code)
          .get();

      if (existingCode.exists) {
        // If code exists, generate a new one recursively
        return await generateCoachInviteCode(coachId: coachId);
      }

      // Create the invite code document
      final inviteCode = CoachInviteCode(
        code: code,
        coachId: coachId,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(
          const Duration(days: 30),
        ), // Valid for 30 days
      );

      await _firestore
          .collection('coachInviteCodes')
          .doc(code)
          .set(inviteCode.toJson());

      // Update coach profile with the invite code
      await _firestore.collection('coachProfiles').doc(coachId).update({
        'inviteCode': code,
      });

      return code;
    } catch (e) {
      throw Exception('Failed to generate coach invite code: $e');
    }
  }

  /// Link a player to a coach using invite code
  Future<void> linkPlayerToCoach({
    required String playerId,
    required String coachCode,
  }) async {
    try {
      // Get the invite code document
      final inviteCodeDoc = await _firestore
          .collection('coachInviteCodes')
          .doc(coachCode)
          .get();

      if (!inviteCodeDoc.exists) {
        throw Exception('Invalid invite code');
      }

      final inviteCode = CoachInviteCode.fromJson(inviteCodeDoc.data()!);

      if (!inviteCode.isValid) {
        throw Exception('Invite code has expired');
      }

      final coachId = inviteCode.coachId;

      // Update player profile with coach ID
      await _firestore.collection('playerProfiles').doc(playerId).update({
        'coachId': coachId,
      });

      // Update coach profile to add player ID
      final coachDoc = await _firestore
          .collection('coachProfiles')
          .doc(coachId)
          .get();

      if (coachDoc.exists) {
        final coachProfile = CoachProfile.fromJson(coachDoc.data()!);
        final updatedCoach = coachProfile.addPlayer(playerId);
        await _firestore
            .collection('coachProfiles')
            .doc(coachId)
            .update(updatedCoach.toJson());
      }
    } catch (e) {
      throw Exception('Failed to link player to coach: $e');
    }
  }

  /// Get all players linked to a coach
  Stream<List<PlayerProfile>> getPlayersForCoach({required String coachId}) {
    return _firestore
        .collection('playerProfiles')
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlayerProfile.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Add coach note to a shot
  Future<void> addCoachNoteToShot({
    required String shotId,
    required String note,
  }) async {
    try {
      await _firestore.collection('shots').doc(shotId).update({
        'coachNotes': note,
      });
    } catch (e) {
      throw Exception('Failed to add coach note to shot: $e');
    }
  }

  /// Get sessions for a specific player (for coach view)
  Future<List<SessionModel>> getSessionsForPlayerByCoach(
    String playerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('playerId', isEqualTo: playerId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SessionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sessions for player: $e');
    }
  }

  /// Stream sessions for a specific player (for coach view)
  Stream<List<SessionModel>> getSessionsStreamForPlayerByCoach(
    String playerId,
  ) {
    return _firestore
        .collection('sessions')
        .where('playerId', isEqualTo: playerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SessionModel.fromJson(doc.data()))
              .toList(),
        );
  }
}
