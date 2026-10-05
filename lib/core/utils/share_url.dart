/// Base do site (sempre path real, sem `#`), para links que o Hosting precisa resolver.
String _siteOrigin() => Uri.base.origin;

/// Link de convite. Quem abre entra na banda com a própria conta.
String projectInviteUrl(String token) => '${_siteOrigin()}/join/$token';

/// Só aceita um caminho interno `/join/<token>`, para o login não redirecionar para fora.
String? safeJoinPath(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final decoded = Uri.decodeQueryComponent(raw);
  final uri = Uri.tryParse(decoded);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  final segments = uri.pathSegments;
  if (segments.length != 2 || segments.first != 'join') return null;
  final token = segments[1];
  if (token.length < 8 || token.length > 64) return null;
  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(token)) return null;
  return '/join/$token';
}

/// URL da SPA (Flutter) — abre o app em `/artist/:id`.
/// Usa só `origin` + path para funcionar com Hosting (`**` → index.html) e path URL strategy.
String artistPublicPageUrl(String profileId) {
  return '${_siteOrigin()}/artist/$profileId';
}

/// URL para WhatsApp/Instagram: path `/share/artist/...` (Hosting → Cloud Function).
/// Query `id` duplica o id: na CF v2 o path às vezes não chega inteiro; a função aceita `?id=`.
/// Nunca use fragmento `#/share/...` — o servidor não recebe o que vem depois de `#`.
String artistSocialShareUrl(String profileId) {
  final q = Uri.encodeQueryComponent(profileId);
  return '${_siteOrigin()}/share/artist/$profileId?id=$q';
}
