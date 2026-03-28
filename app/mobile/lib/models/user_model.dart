class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final int totalPoints;
  final int totalMinutesLearned;
  final List<String> completedTopics;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.lastLoginAt,
    this.totalPoints = 0,
    this.totalMinutesLearned = 0,
    this.completedTopics = const [],
  });

  /// Convert from Firestore document data
  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      fullName: data['full name'] as String? ?? 'User',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as dynamic)?.toDate(),
      totalPoints: data['totalPoints'] as int? ?? 0,
      totalMinutesLearned: data['totalMinutesLearned'] as int? ?? 0,
      completedTopics: List<String>.from(
        data['completedTopics'] as List? ?? [],
      ),
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'full name': fullName,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'totalPoints': totalPoints,
      'totalMinutesLearned': totalMinutesLearned,
      'completedTopics': completedTopics,
    };
  }

  /// Create a copy with modified fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? totalPoints,
    int? totalMinutesLearned,
    List<String>? completedTopics,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalPoints: totalPoints ?? this.totalPoints,
      totalMinutesLearned: totalMinutesLearned ?? this.totalMinutesLearned,
      completedTopics: completedTopics ?? this.completedTopics,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName)';
  }
}
