class Note {
  String id;
  String name;
  String content;
  String categoryId;
  DateTime createdAt;

  Note({
    required this.id,
    required this.name,
    required this.content,
    required this.categoryId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'content': content,
      'categoryId': categoryId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      name: map['name'] ?? '',
      content: map['content'] ?? '',
      categoryId: map['categoryId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
