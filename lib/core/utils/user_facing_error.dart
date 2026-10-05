import 'package:flutter/foundation.dart';

/// Evita expor exceções brutas em produção; mantém detalhe em debug.
String userFacingErrorSuffix(Object? error) {
  if (!kDebugMode || error == null) return '';
  return ' (${error.toString()})';
}
