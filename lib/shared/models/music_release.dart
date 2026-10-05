/// Planejamento de lançamento musical
class MusicRelease {
  final String id;
  final String profileId;
  final String title;
  /// single | ep | album
  final String type;
  final DateTime releaseDate;
  /// planning | in_progress | released | cancelled
  final String status;
  final String notes;
  final Map<String, bool> milestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MusicRelease({
    required this.id,
    required this.profileId,
    required this.title,
    required this.type,
    required this.releaseDate,
    required this.status,
    required this.notes,
    required this.milestones,
    required this.createdAt,
    required this.updatedAt,
  });

  static const typeSingle = 'single';
  static const typeEp = 'ep';
  static const typeAlbum = 'album';

  static const statusPlanning = 'planning';
  static const statusInProgress = 'in_progress';
  static const statusReleased = 'released';
  static const statusCancelled = 'cancelled';

  static const milestoneCover = 'cover_done';
  static const milestoneDistribution = 'distribution_sent';
  static const milestoneTeaser = 'teaser_scheduled';
  static const milestonePress = 'press_release';
  static const milestonePromotion = 'promotion_done';

  factory MusicRelease.fromMap(String id, String profileId, Map<String, dynamic> map) {
    final mRaw = map['milestones'];
    final milestones = <String, bool>{};
    if (mRaw is Map) {
      for (final e in mRaw.entries) {
        milestones[e.key.toString()] = e.value == true;
      }
    }
    return MusicRelease(
      id: id,
      profileId: profileId,
      title: map['title']?.toString() ?? '',
      type: map['type']?.toString() ?? typeSingle,
      releaseDate: map['releaseDate'] != null
          ? DateTime.parse(map['releaseDate'] as String)
          : DateTime.now(),
      status: map['status']?.toString() ?? statusPlanning,
      notes: map['notes']?.toString() ?? '',
      milestones: milestones,
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
      'type': type,
      'releaseDate': DateTime(
        releaseDate.year,
        releaseDate.month,
        releaseDate.day,
      ).toIso8601String(),
      'status': status,
      'notes': notes,
      'milestones': milestones,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MusicRelease copyWith({
    String? title,
    String? type,
    DateTime? releaseDate,
    String? status,
    String? notes,
    Map<String, bool>? milestones,
    DateTime? updatedAt,
  }) {
    return MusicRelease(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      type: type ?? this.type,
      releaseDate: releaseDate ?? this.releaseDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      milestones: milestones ?? Map<String, bool>.from(this.milestones),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isPastReleased {
    final d = DateTime(releaseDate.year, releaseDate.month, releaseDate.day);
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    return d.isBefore(t0);
  }
}
