/// Constantes da aplicação Music Map
class AppConstants {
  AppConstants._();

  // Marca
  static const String appName = 'Music Map';
  static const String appTagline = 'O mapa da cena musical';

  /// Vagas para o pré-lançamento
  static const int earlyAccessLimit = 500;

  /// Vagas já reservadas (contam no total exibido)
  static const int earlyAccessReserved = 64;

  // Firebase paths
  static const String totalProfilesPath = 'stats/totalProfiles';
  static const String usersPath = 'users';
  static const String profilesPath = 'profiles';
  static const String profilesByOwnerPath = 'profiles_by_owner';

  // Valores de perfil
  static const String artistTypeSolo = 'artista solo';
  static const String artistTypeBand = 'banda';

  static const List<String> artistTypes = [artistTypeSolo, artistTypeBand];

  /// Web Client ID do Google OAuth (Firebase Console > Auth > Sign-in method > Google)
  static const String googleWebClientId =
      '968493250566-8h4k3n4skhn3fgcb2gob6hls1rb6oegf.apps.googleusercontent.com';

  /// Declaração obrigatória ao criar conta ou perfil
  static const String representationDeclaration =
      'Declaro que só cadastro bandas/artistas dos quais sou integrante ou representante oficial, e que não criarei perfis em nome de terceiros sem autorização.';

  /// Estados brasileiros (UF - Nome) para dropdown
  static const List<MapEntry<String, String>> brazilianStates = [
    MapEntry('AC', 'Acre'),
    MapEntry('AL', 'Alagoas'),
    MapEntry('AP', 'Amapá'),
    MapEntry('AM', 'Amazonas'),
    MapEntry('BA', 'Bahia'),
    MapEntry('CE', 'Ceará'),
    MapEntry('DF', 'Distrito Federal'),
    MapEntry('ES', 'Espírito Santo'),
    MapEntry('GO', 'Goiás'),
    MapEntry('MA', 'Maranhão'),
    MapEntry('MT', 'Mato Grosso'),
    MapEntry('MS', 'Mato Grosso do Sul'),
    MapEntry('MG', 'Minas Gerais'),
    MapEntry('PA', 'Pará'),
    MapEntry('PB', 'Paraíba'),
    MapEntry('PR', 'Paraná'),
    MapEntry('PE', 'Pernambuco'),
    MapEntry('PI', 'Piauí'),
    MapEntry('RJ', 'Rio de Janeiro'),
    MapEntry('RN', 'Rio Grande do Norte'),
    MapEntry('RS', 'Rio Grande do Sul'),
    MapEntry('RO', 'Rondônia'),
    MapEntry('RR', 'Roraima'),
    MapEntry('SC', 'Santa Catarina'),
    MapEntry('SP', 'São Paulo'),
    MapEntry('SE', 'Sergipe'),
    MapEntry('TO', 'Tocantins'),
  ];

  /// Gêneros musicais para dropdown
  static const List<String> musicGenres = [
    'Axé',
    'Blues',
    'Bossa Nova',
    'Brega',
    'Clássico',
    'Country',
    'Cuarteto',
    'Dance',
    'Eletrônica',
    'Emo',
    'Folk',
    'Forró',
    'Funk',
    'Gospel',
    'Grunge',
    'Hardcore',
    'Hip Hop',
    'House',
    'Indie',
    'Jazz',
    'K-Pop',
    'MPB',
    'Metal',
    'Pagode',
    'Pop',
    'Punk',
    'R&B',
    'Rap',
    'Reggae',
    'Rock',
    'Samba',
    'Sertanejo',
    'Soul',
    'Tecno',
    'Trap',
    'Outro',
  ];

  static const List<String> interestOptions = [
    'tocar em shows',
    'collabs',
    'ser encontrado por produtoras',
    'divulgar lançamentos',
  ];
}
