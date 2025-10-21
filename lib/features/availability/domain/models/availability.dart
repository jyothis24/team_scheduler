class Availability {
  final int id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;

  const Availability({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }

  Availability copyWith({
    int? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
  }) {
    return Availability(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters for UI
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  String get slotStart {
    return startTime.toIso8601String().substring(11, 16); // HH:MM format
  }

  String get slotEnd {
    return endTime.toIso8601String().substring(11, 16); // HH:MM format
  }

  String get formattedSlot {
    return '$slotStart - $slotEnd';
  }

  @override
  String toString() {
    return 'Availability(id: $id, userId: $userId, startTime: $startTime, endTime: $endTime, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Availability &&
        other.id == id &&
        other.userId == userId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        createdAt.hashCode;
  }
}
