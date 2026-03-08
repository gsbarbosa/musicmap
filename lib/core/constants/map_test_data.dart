/// Pins de teste para o mapa do Brasil
///
/// Para remover: defina [enableMapTestPins] = false
/// Os dados reais vêm sempre do banco (getLocationCountsByState);
/// este mapa é SOMADO ao resultado quando a flag está ativa.
class MapTestData {
  MapTestData._();

  /// Define como false para exibir apenas dados reais do banco
  static const bool enableMapTestPins = true;

  /// Contagem fictícia por estado (UF)
  /// SP, RJ e MG com mais pins; outros estados com valores menores
  static const Map<String, int> testStateCounts = {
    'SP': 18,
    'RJ': 12,
    'MG': 14,
    'RS': 4,
    'PR': 5,
    'SC': 3,
    'BA': 3,
    'PE': 2,
    'CE': 2,
    'DF': 3,
    'GO': 2,
    'ES': 2,
    'PB': 1,
    'RN': 1,
    'AL': 1,
    'SE': 1,
    'MA': 1,
    'PI': 1,
  };
}
