class Question {
  final String id;
  final String text;
  final String? hint;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    required this.text,
    this.hint,
    this.order = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'hint': hint,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from map
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      hint: map['hint'],
      order: map['order'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // Copy with
  Question copyWith({
    String? id,
    String? text,
    String? hint,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      hint: hint ?? this.hint,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}