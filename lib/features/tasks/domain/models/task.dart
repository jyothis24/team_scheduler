class Task {
  final int id;
  final String title;
  final String? description;
  final String createdBy;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final List<String>
      collaborators; // This will be populated from task_collaborators table

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    this.startTime,
    this.endTime,
    required this.createdAt,
    this.collaborators = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      collaborators: List<String>.from(json['collaborators'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'collaborators': collaborators,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'created_by': createdBy,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    List<String>? collaborators,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      collaborators: collaborators ?? this.collaborators,
    );
  }

  // Helper getters for UI
  int get durationMinutes {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!).inMinutes;
    }
    return 0;
  }

  String? get slotStart {
    return startTime?.toIso8601String().substring(11, 16); // HH:MM format
  }

  String? get slotEnd {
    return endTime?.toIso8601String().substring(11, 16); // HH:MM format
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, description: $description, createdBy: $createdBy, startTime: $startTime, endTime: $endTime, createdAt: $createdAt, collaborators: $collaborators)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.createdBy == createdBy &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.createdAt == createdAt &&
        other.collaborators == collaborators;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        createdBy.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        createdAt.hashCode ^
        collaborators.hashCode;
  }
}
