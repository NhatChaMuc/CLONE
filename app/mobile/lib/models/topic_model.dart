class TopicModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int difficulty; // 1-5
  final int totalLessons;
  final List<String> keywords;

  TopicModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.difficulty,
    required this.totalLessons,
    this.keywords = const [],
  });

  /// Convert from API JSON response
  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      difficulty: json['difficulty'] as int? ?? 1,
      totalLessons: json['totalLessons'] as int? ?? 0,
      keywords: List<String>.from(json['keywords'] as List? ?? []),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'difficulty': difficulty,
      'totalLessons': totalLessons,
      'keywords': keywords,
    };
  }

  /// Create a copy with modified fields
  TopicModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? difficulty,
    int? totalLessons,
    List<String>? keywords,
  }) {
    return TopicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      difficulty: difficulty ?? this.difficulty,
      totalLessons: totalLessons ?? this.totalLessons,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  String toString() {
    return 'TopicModel(id: $id, title: $title, difficulty: $difficulty)';
  }
}
