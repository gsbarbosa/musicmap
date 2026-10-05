/// Show agendado (pertence a um perfil artista/banda)
class ArtistShow {
  final String id;
  final String profileId;
  final String title;
  final DateTime date;
  final String time;
  final String venue;
  final String city;
  final String notes;
  /// confirmed | pending | cancelled
  final String status;
  /// Tipo de compromisso: show | rehearsal | recording
  final String eventKind;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtistShow({
    required this.id,
    required this.profileId,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.city,
    required this.notes,
    required this.status,
    this.eventKind = eventKindShow,
    required this.createdAt,
    required this.updatedAt,
  });

  static const eventKindShow = 'show';
  static const eventKindRehearsal = 'rehearsal';
  static const eventKindRecording = 'recording';

  static const List<String> eventKindOrder = [
    eventKindShow,
    eventKindRehearsal,
    eventKindRecording,
  ];

  static const statusConfirmed = 'confirmed';
  static const statusPending = 'pending';
  static const statusCancelled = 'cancelled';

  static const List<String> statusLabelsOrder = [
    statusConfirmed,
    statusPending,
    statusCancelled,
  ];

  factory ArtistShow.fromMap(String id, String profileId, Map<String, dynamic> map) {
    return ArtistShow(
      id: id,
      profileId: profileId,
      title: map['title']?.toString() ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      time: map['time']?.toString() ?? '',
      venue: map['venue']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      status: map['status']?.toString() ?? statusPending,
      eventKind: map['eventKind']?.toString() ?? eventKindShow,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'time': time,
      'venue': venue,
      'city': city,
      'notes': notes,
      'status': status,
      'eventKind': eventKind,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ArtistShow copyWith({
    String? title,
    DateTime? date,
    String? time,
    String? venue,
    String? city,
    String? notes,
    String? status,
    String? eventKind,
    DateTime? updatedAt,
  }) {
    return ArtistShow(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      eventKind: eventKind ?? this.eventKind,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isPast {
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    return d.isBefore(t0);
  }
}
