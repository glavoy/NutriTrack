class UserNote {
  final String? userId;
  final String note;
  final DateTime updatedAt;
  final bool isSynced;

  UserNote({
    this.userId,
    required this.note,
    required this.updatedAt,
    this.isSynced = true,
  });

  factory UserNote.empty() {
    return UserNote(
      note: '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory UserNote.fromJson(Map<String, dynamic> json) {
    return UserNote(
      userId: json['user_id'],
      note: json['note'] ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user_id': userId,
      'note': note,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  UserNote copyWith({
    String? userId,
    String? note,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return UserNote(
      userId: userId ?? this.userId,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
