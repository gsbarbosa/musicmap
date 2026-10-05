/// Membro de um projeto (linha em `profile_members/{profileId}/{uid}`)
class ProfileMemberEntry {
  final String userId;
  final String role;
  final DateTime? joinedAt;

  const ProfileMemberEntry({
    required this.userId,
    required this.role,
    this.joinedAt,
  });

  factory ProfileMemberEntry.fromMap(String userId, Map<String, dynamic> map) {
    final j = map['joinedAt']?.toString();
    return ProfileMemberEntry(
      userId: userId,
      role: map['role']?.toString() ?? 'editor',
      joinedAt: j != null && j.isNotEmpty ? DateTime.tryParse(j) : null,
    );
  }
}
