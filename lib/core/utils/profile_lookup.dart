/// Utilitário para gerar chave de lookup de perfil (nome + instagram)
/// Usado para verificar duplicatas
String normalizeProfileLookupKey(String artistName, String instagram) {
  final name = artistName
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  final ig = instagram
      .replaceAll('@', '')
      .toLowerCase()
      .trim();
  return '${name}|$ig';
}
