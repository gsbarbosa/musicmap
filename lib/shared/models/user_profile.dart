import 'package:palace_pulse/core/constants/app_constants.dart';

/// Modelo do perfil de artista/banda
/// Estrutura pensada para escalabilidade futura (mapa, busca, perfis públicos)
class UserProfile {
  final String userId;
  final String artistName;
  final String artistType;
  final String city;
  final String state;
  final String genre;
  final String instagram;
  final String contact;
  final String? spotify;
  final String? youtube;
  final String? tiktok;
  final String? bio;
  final List<String> interests;
  final bool earlyAccess;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    required this.artistName,
    required this.artistType,
    required this.city,
    required this.state,
    required this.genre,
    required this.instagram,
    required this.contact,
    this.spotify,
    this.youtube,
    this.tiktok,
    this.bio,
    this.interests = const [],
    this.earlyAccess = true,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(String userId, Map<String, dynamic> map) {
    return UserProfile(
      userId: userId,
      artistName: map['artistName'] ?? '',
      artistType: map['artistType'] ?? AppConstants.artistTypeSolo,
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      genre: map['genre'] ?? '',
      instagram: map['instagram'] ?? '',
      contact: map['contact'] ?? '',
      spotify: map['spotify'] as String?,
      youtube: map['youtube'] as String?,
      tiktok: map['tiktok'] as String?,
      bio: map['bio'] as String?,
      interests: map['interests'] != null
          ? List<String>.from(map['interests'] as List)
          : [],
      earlyAccess: map['earlyAccess'] ?? true,
      status: map['status'] ?? 'active',
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
      'artistName': artistName,
      'artistType': artistType,
      'city': city,
      'state': state,
      'genre': genre,
      'instagram': instagram,
      'contact': contact,
      'spotify': spotify,
      'youtube': youtube,
      'tiktok': tiktok,
      'bio': bio,
      'interests': interests,
      'earlyAccess': earlyAccess,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? artistName,
    String? artistType,
    String? city,
    String? state,
    String? genre,
    String? instagram,
    String? contact,
    String? spotify,
    String? youtube,
    String? tiktok,
    String? bio,
    List<String>? interests,
  }) {
    return UserProfile(
      userId: userId,
      artistName: artistName ?? this.artistName,
      artistType: artistType ?? this.artistType,
      city: city ?? this.city,
      state: state ?? this.state,
      genre: genre ?? this.genre,
      instagram: instagram ?? this.instagram,
      contact: contact ?? this.contact,
      spotify: spotify ?? this.spotify,
      youtube: youtube ?? this.youtube,
      tiktok: tiktok ?? this.tiktok,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      earlyAccess: earlyAccess,
      status: status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
