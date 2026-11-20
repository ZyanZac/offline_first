class Task {
  final String id;
  final String title;
  final bool isSynced;
  final DateTime updatedAt;
  final bool isDeleted;
  const Task({required this.id, required this.title, required this.updatedAt, this.isSynced = false, this.isDeleted = false});
  Task copyWith({String? title, bool? isSynced, DateTime? updatedAt, bool? isDeleted}) => Task(
        id: id,
        title: title ?? this.title,
        updatedAt: updatedAt ?? this.updatedAt,
        isSynced: isSynced ?? this.isSynced,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Map<String, Object?> toMap({bool? isSynced}) => {
        'id': id,
        'title': title,
        'is_synced': (isSynced ?? this.isSynced) ? 1 : 0,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'is_deleted': isDeleted ? 1 : 0,
      };
  factory Task.fromMap(Map<String, Object?> m) => Task(
        id: m['id'] as String,
        title: m['title'] as String,
        isSynced: m['is_synced'] == 1,
        updatedAt: DateTime.parse(m['updated_at'] as String),
        isDeleted: m['is_deleted'] == 1,
      );
  Map<String, Object?> toRemote() => {
        'id': id,
        'title': title,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'is_deleted': isDeleted,
      };
  factory Task.fromRemote(Map<String, dynamic> d) => Task(
        id: d['id'] as String,
        title: d['title'] as String,
        isSynced: true,
        updatedAt: DateTime.parse(d['updated_at'] as String),
        isDeleted: d['is_deleted'] == true,
      );
}