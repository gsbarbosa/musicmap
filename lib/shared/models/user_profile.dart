import 'package:palace_pulse/core/constants/app_constants.dart';

/// Modelo do perfil de artista/banda
/// Um usuário pode ter vários perfis (várias bandas/artistas)
class UserProfile {
  final String id;
  final String ownerUserId;
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
  /// Visível na página pública `/artist/:id` quando [status] é active
  final bool publicProfile;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? representationDeclarationAcceptedAt;

  const UserProfile({
    required this.id,
    required this.ownerUserId,
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
    this.publicProfile = true,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.representationDeclarationAcceptedAt,
  });

  factory UserProfile.fromMap(String profileId, Map<String, dynamic> map, {String? ownerUserIdOverride}) {
    return UserProfile(
      id: profileId,
      ownerUserId: ownerUserIdOverride ?? map['ownerUserId'] ?? '',
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
      publicProfile: map['publicProfile'] ?? true,
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      representationDeclarationAcceptedAt: map['representationDeclarationAcceptedAt'] != null
          ? DateTime.parse(map['representationDeclarationAcceptedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
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
      'publicProfile': publicProfile,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (representationDeclarationAcceptedAt != null)
        'representationDeclarationAcceptedAt':
            representationDeclarationAcceptedAt!.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? ownerUserId,
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
    bool? earlyAccess,
    String? status,
    bool? publicProfile,
    String? photoUrl,
    DateTime? representationDeclarationAcceptedAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
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
      representationDeclarationAcceptedAt:
          representationDeclarationAcceptedAt ?? this.representationDeclarationAcceptedAt,
      earlyAccess: earlyAccess ?? this.earlyAccess,
      status: status ?? this.status,
      publicProfile: publicProfile ?? this.publicProfile,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
