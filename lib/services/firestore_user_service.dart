import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user profile data
class UserProfile {
  final String userId;
  final String email;
  final String username;
  final int xp;
  final bool roomClean;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.email,
    required this.username,
    this.xp = 0,
    this.roomClean = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'xp': xp,
      'roomClean': roomClean,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      xp: data['xp'] ?? 0,
      roomClean: data['roomClean'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? userId,
    String? email,
    String? username,
    int? xp,
    bool? roomClean,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      xp: xp ?? this.xp,
      roomClean: roomClean ?? this.roomClean,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Service for managing user profile data in Firestore
class FirestoreUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Create new user profile
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String username,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      userId: userId,
      email: email,
      username: username,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .set(profile.toFirestore());
  }

  /// Get user profile by userId
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user XP
  Future<void> updateXp(String userId, int newXp) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'xp': newXp,
      'updatedAt': DateTime.now(),
    });
  }

  /// Update room clean status
  Future<void> updateRoomCleanStatus(String userId, bool isClean) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'roomClean': isClean,
      'updatedAt': DateTime.now(),
    });
  }

  /// Update username
  Future<void> updateUsername(String userId, String newUsername) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'username': newUsername,
      'updatedAt': DateTime.now(),
    });
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).delete();
  }

  /// Stream of user profile changes
  Stream<UserProfile?> userProfileStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }
}