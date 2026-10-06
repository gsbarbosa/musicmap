/// Constantes da aplicação Music Map
class AppConstants {
  AppConstants._();

  // Marca
  static const String appName = 'Music Map';
  static const String appTagline = 'O hub da sua carreira musical';
  /// Monograma compacto na navegação (iniciais alinhadas a [appName])
  static const String appMonogram = 'MM';

  // Firebase paths
  static const String totalProfilesPath = 'stats/totalProfiles';
  /// Contador de aberturas da página pública (gravado por Cloud Function)
  static const String profileViewsPath = 'stats/profile_views';

  /// Query `?ref=` na landing/cadastro para rastrear origem (ex.: landing, parceiro_x)
  static const String referralQueryParam = 'ref';
  static const String referralLandingValue = 'landing';
  static const String usersPath = 'users';
  /// Ficha da pessoa, legível por quem está logado: `people/{uid}`
  static const String peoplePath = 'people';
  static const String profilesPath = 'profiles';
  static const String profilesByOwnerPath = 'profiles_by_owner';
  /// Acesso compartilhado: `user_profile_access/{uid}/{profileId}` → role, joinedAt
  static const String userProfileAccessPath = 'user_profile_access';
  /// Membros por projeto: `profile_members/{profileId}/{memberUid}`
  static const String profileMembersPath = 'profile_members';
  /// Convites por token: `invite_by_code/{token}` (criação pelo dono; uso via Cloud Function)
  static const String inviteByCodePath = 'invite_by_code';
  static const String adminUsersPath = 'admin_users';

  /// Papéis em projeto compartilhado (valor em RTDB)
  static const String roleAdmin = 'admin';
  static const String roleEditor = 'editor';
  static const String roleViewer = 'viewer';

  /// Agenda de shows por perfil: `shows/{profileId}/{showId}`
  static const String showsPath = 'shows';
  /// GigBag por perfil: `gigbag/{profileId}/{checklistId}`
  static const String gigbagPath = 'gigbag';
  /// Lançamentos por perfil: `releases/{profileId}/{releaseId}`
  static const String releasesPath = 'releases';
  /// Tarefas operacionais por perfil: `operational_tasks/{profileId}/{taskId}`
  static const String operationalTasksPath = 'operational_tasks';
  /// Caixa da banda: `ledger/{profileId}/{entryId}`
  static const String ledgerPath = 'ledger';

  /// Emails com acesso ao painel admin (export CSV). Opcional: use também `admin_users/{uid}` no Realtime Database.
  static const List<String> adminEmails = [];

  // Valores de perfil
  static const String artistTypeSolo = 'artista solo';
  static const String artistTypeBand = 'banda';

  static const List<String> artistTypes = [artistTypeSolo, artistTypeBand];

  /// Instrumentos da ficha da pessoa (valor gravado no RTDB)
  static const List<String> instrumentOptions = [
    'voz',
    'guitarra',
    'baixo',
    'bateria',
    'teclado',
    'percussão',
    'sopro',
    'produção',
    'técnico',
  ];

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
