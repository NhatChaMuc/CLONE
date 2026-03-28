import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

/// Repository for handling practice-related operations
class PracticeRepository {
  final FirebaseFirestore _firestore;

  PracticeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Record a new practice session
  Future<void> recordPractice(PracticeModel practice) async {
    try {
      await _firestore
          .collection('practices')
          .doc(practice.id)
          .set(practice.toFirestore());

      // Update user's total points and minutes
      await _firestore.collection('users').doc(practice.userId).update({
        'totalPoints': FieldValue.increment(practice.pointsEarned),
        'totalMinutesLearned': FieldValue.increment(
          1,
        ), // TODO: Calculate actual minutes
      });
    } catch (e) {
      throw DataException(
        message: 'Failed to record practice',
        originalException: e,
      );
    }
  }

  /// Get user's practice history
  Future<List<PracticeModel>> getPracticeHistory({
    required String userId,
    int limit = 100,
  }) async {
    try {
      final query = await _firestore
          .collection('practices')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return [
        for (final doc in query.docs)
          PracticeModel.fromFirestore(doc.id, doc.data()),
      ];
    } catch (e) {
      throw DataException(
        message: 'Failed to fetch practice history',
        originalException: e,
      );
    }
  }

  /// Get practices for a specific topic
  Future<List<PracticeModel>> getPracticesByTopic({
    required String userId,
    required String topicId,
  }) async {
    try {
      final query = await _firestore
          .collection('practices')
          .where('userId', isEqualTo: userId)
          .where('topicId', isEqualTo: topicId)
          .orderBy('createdAt', descending: true)
          .get();

      return [
        for (final doc in query.docs)
          PracticeModel.fromFirestore(doc.id, doc.data()),
      ];
    } catch (e) {
      throw DataException(
        message: 'Failed to fetch practices for topic',
        originalException: e,
      );
    }
  }

  /// Get user's statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final practiceQuery = await _firestore
          .collection('practices')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      final practices = [
        for (final doc in practiceQuery.docs)
          PracticeModel.fromFirestore(doc.id, doc.data()),
      ];

      // Calculate statistics
      final totalPoints = practices.fold<int>(
        0,
        (total, practice) => total + practice.pointsEarned,
      );

      final accuracyValues = practices.map((p) => p.accuracy ?? 0.0).toList();
      final avgAccuracy = accuracyValues.isEmpty
          ? 0.0
          : accuracyValues.reduce((a, b) => a + b) / accuracyValues.length;

      final topicIds = <String>{
        for (final practice in practices) practice.topicId,
      };

      return {
        'totalPractices': practices.length,
        'totalPoints': totalPoints,
        'averageAccuracy': avgAccuracy,
        'completedTopics': topicIds.length,
        'practiceTypeBreakdown': _calculatePracticeTypeBreakdown(practices),
      };
    } catch (e) {
      throw DataException(
        message: 'Failed to fetch user statistics',
        originalException: e,
      );
    }
  }

  /// Calculate practice type breakdown
  Map<String, int> _calculatePracticeTypeBreakdown(
    List<PracticeModel> practices,
  ) {
    final breakdown = <String, int>{};

    for (final practice in practices) {
      breakdown[practice.practiceType] =
          (breakdown[practice.practiceType] ?? 0) + 1;
    }

    return breakdown;
  }
}
