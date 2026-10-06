/// Membro de um projeto (linha em `profile_members/{profileId}/{uid}`)
class ProfileMemberEntry {
  final String userId;
  final String role;
  final DateTime? joinedAt;
  /// Nome visto pela banda. A ficha pessoal tem prioridade quando existe.
  final String displayName;
  final List<String> instruments;
  final String city;
  final String state;
  final String email;

  const ProfileMemberEntry({
    required this.userId,
    required this.role,
    this.joinedAt,
    this.displayName = '',
    this.instruments = const [],
    this.city = '',
    this.state = '',
    this.email = '',
  });

  factory ProfileMemberEntry.fromMap(String userId, Map<String, dynamic> map) {
    final j = map['joinedAt']?.toString();
    return ProfileMemberEntry(
      userId: userId,
      role: map['role']?.toString() ?? 'editor',
      joinedAt: j != null && j.isNotEmpty ? DateTime.tryParse(j) : null,
      displayName: map['displayName']?.toString() ?? '',
      instruments: _instrumentsFrom(map['instruments']),
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }

  static List<String> _instrumentsFrom(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (raw is Map) {
      return raw.keys.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }
}
