class PracticeModel {
  final String id;
  final String userId;
  final String topicId;
  final String
  practiceType; // 'conversation', 'shadowing', 'transcribe', 'tongue_twister'
  final String sentence;
  final String? transcribedText;
  final double? accuracy;
  final int pointsEarned;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;

  PracticeModel({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.practiceType,
    required this.sentence,
    this.transcribedText,
    this.accuracy,
    this.pointsEarned = 0,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
  });

  /// Convert from Firestore document data
  factory PracticeModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PracticeModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      topicId: data['topicId'] as String? ?? '',
      practiceType: data['practiceType'] as String? ?? '',
      sentence: data['sentence'] as String? ?? '',
      transcribedText: data['transcribedText'] as String?,
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      pointsEarned: data['pointsEarned'] as int? ?? 0,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as dynamic)?.toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'topicId': topicId,
      'practiceType': practiceType,
      'sentence': sentence,
      'transcribedText': transcribedText,
      'accuracy': accuracy,
      'pointsEarned': pointsEarned,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'isCompleted': isCompleted,
    };
  }

  /// Create a copy with modified fields
  PracticeModel copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? practiceType,
    String? sentence,
    String? transcribedText,
    double? accuracy,
    int? pointsEarned,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return PracticeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      practiceType: practiceType ?? this.practiceType,
      sentence: sentence ?? this.sentence,
      transcribedText: transcribedText ?? this.transcribedText,
      accuracy: accuracy ?? this.accuracy,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'PracticeModel(id: $id, practiceType: $practiceType, accuracy: $accuracy)';
  }
}
