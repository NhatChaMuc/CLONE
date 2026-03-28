import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

/// Provides the Firestore instance
final firestoreProvider = Provider((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for fetching user data from Firestore
final userDataProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) async {
  final firestore = ref.watch(firestoreProvider);

  try {
    final doc = await firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw NotFoundException(message: 'User not found');
    }

    return UserModel.fromFirestore(doc.id, doc.data()!);
  } catch (e) {
    throw DataException(
      message: 'Failed to load user data',
      originalException: e,
    );
  }
});

/// Provider for user's practice history
final userPracticeHistoryProvider =
    FutureProvider.family<List<PracticeModel>, String>((ref, userId) async {
      final firestore = ref.watch(firestoreProvider);

      try {
        final query = await firestore
            .collection('practices')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();

        return [
          for (final doc in query.docs)
            PracticeModel.fromFirestore(doc.id, doc.data()),
        ];
      } catch (e) {
        throw DataException(
          message: 'Failed to load practice history',
          originalException: e,
        );
      }
    });

/// Provider for user's statistics
final userStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) async {
  final firestore = ref.watch(firestoreProvider);

  try {
    final practiceQuery = await firestore
        .collection('practices')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .get();

    final practices = [
      for (final doc in practiceQuery.docs)
        PracticeModel.fromFirestore(doc.id, doc.data()),
    ];

    final totalPoints = practices.fold<int>(
      0,
      (total, practice) => total + practice.pointsEarned,
    );

    final avgAccuracy = practices.isEmpty
        ? 0.0
        : practices.map((p) => p.accuracy ?? 0.0).reduce((a, b) => a + b) /
              practices.length;

    return {
      'totalPractices': practices.length,
      'totalPoints': totalPoints,
      'averageAccuracy': avgAccuracy,
      'completedTopics': <String>{
        for (final practice in practices) practice.topicId,
      }.length,
    };
  } catch (e) {
    throw DataException(
      message: 'Failed to load user statistics',
      originalException: e,
    );
  }
});

/// Notifier for user profile updates
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
      return UserProfileNotifier(ref);
    });

class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  UserProfileNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Update user profile in Firestore
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? email,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestore = ref.read(firestoreProvider);

      final updateData = <String, dynamic>{
        if (fullName != null) 'full name': fullName,
        if (email != null) 'email': email,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await firestore.collection('users').doc(uid).update(updateData);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(
        DataException(
          message: 'Failed to update profile',
          originalException: e,
        ),
        StackTrace.current,
      );
    }
  }

  /// Record a practice session
  Future<void> recordPractice({
    required String userId,
    required PracticeModel practice,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestore = ref.read(firestoreProvider);

      // Save practice to Firestore
      await firestore
          .collection('practices')
          .doc(practice.id)
          .set(practice.toFirestore());

      // Update user's total points
      await firestore.collection('users').doc(userId).update({
        'totalPoints': FieldValue.increment(practice.pointsEarned),
      });

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(
        DataException(
          message: 'Failed to record practice',
          originalException: e,
        ),
        StackTrace.current,
      );
    }
  }
}
