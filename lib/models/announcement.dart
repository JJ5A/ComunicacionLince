class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.createdAt,
    this.category = 'General',
    this.acknowledgedBy = const <String>{},
  });

  final String id;
  final String title;
  final String body;
  final String authorId;
  final DateTime createdAt;
  final String category;
  final Set<String> acknowledgedBy;

  bool isAcknowledged(String userId) => acknowledgedBy.contains(userId);

  Announcement copyWith({
    String? title,
    String? body,
    String? category,
    Set<String>? acknowledgedBy,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      authorId: authorId,
      createdAt: createdAt,
      category: category ?? this.category,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    );
  }
}
