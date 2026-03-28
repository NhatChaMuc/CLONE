class TranscriptionResultModel {
  final String id;
  final String sentence;
  final String transcribedText;
  final double accuracy;
  final List<String> errors;
  final int pointsEarned;
  final DateTime timestamp;

  TranscriptionResultModel({
    required this.id,
    required this.sentence,
    required this.transcribedText,
    required this.accuracy,
    this.errors = const [],
    this.pointsEarned = 0,
    required this.timestamp,
  });

  /// Convert from API JSON response
  factory TranscriptionResultModel.fromJson(Map<String, dynamic> json) {
    return TranscriptionResultModel(
      id: json['id'] as String? ?? '',
      sentence: json['sentence'] as String? ?? '',
      transcribedText: json['transcribedText'] as String? ?? '',
      accuracy: (json['accuracy'] as num? ?? 0).toDouble(),
      errors: List<String>.from(json['errors'] as List? ?? []),
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sentence': sentence,
      'transcribedText': transcribedText,
      'accuracy': accuracy,
      'errors': errors,
      'pointsEarned': pointsEarned,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  TranscriptionResultModel copyWith({
    String? id,
    String? sentence,
    String? transcribedText,
    double? accuracy,
    List<String>? errors,
    int? pointsEarned,
    DateTime? timestamp,
  }) {
    return TranscriptionResultModel(
      id: id ?? this.id,
      sentence: sentence ?? this.sentence,
      transcribedText: transcribedText ?? this.transcribedText,
      accuracy: accuracy ?? this.accuracy,
      errors: errors ?? this.errors,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'TranscriptionResultModel(accuracy: ${(accuracy * 100).toStringAsFixed(1)}%, points: $pointsEarned)';
  }
}
