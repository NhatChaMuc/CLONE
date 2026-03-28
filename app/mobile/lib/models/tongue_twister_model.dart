class TongueTwisterModel {
  final String id;
  final String text;
  final String difficulty; // 'easy', 'medium', 'hard'
  final List<String> keywords;
  final String? audioUrl;

  TongueTwisterModel({
    required this.id,
    required this.text,
    required this.difficulty,
    this.keywords = const [],
    this.audioUrl,
  });

  /// Convert from API JSON response
  factory TongueTwisterModel.fromJson(Map<String, dynamic> json) {
    return TongueTwisterModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'medium',
      keywords: List<String>.from(json['keywords'] as List? ?? []),
      audioUrl: json['audioUrl'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'difficulty': difficulty,
      'keywords': keywords,
      'audioUrl': audioUrl,
    };
  }

  /// Create a copy with modified fields
  TongueTwisterModel copyWith({
    String? id,
    String? text,
    String? difficulty,
    List<String>? keywords,
    String? audioUrl,
  }) {
    return TongueTwisterModel(
      id: id ?? this.id,
      text: text ?? this.text,
      difficulty: difficulty ?? this.difficulty,
      keywords: keywords ?? this.keywords,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  @override
  String toString() {
    return 'TongueTwisterModel(id: $id, difficulty: $difficulty)';
  }
}
