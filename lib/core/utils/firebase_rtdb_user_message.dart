import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Mensagem amigável para falhas ao salvar no Realtime Database (perfil, etc.)
String firebaseRtdbSaveUserMessage(Object error) {
  if (error is StateError) {
    final m = error.message;
    if (m == 'not_authenticated') {
      return 'Sessão expirada ou inválida. Faça login novamente.';
    }
    if (m == 'owner_mismatch') {
      return 'Conta inconsistente com o perfil. Saia, entre de novo e tente outra vez.';
    }
  }
  if (error is PlatformException) {
    final c = (error.code).toLowerCase();
    if (c.contains('permission') || c.contains('denied')) {
      return 'Sem permissão para salvar. Saia e entre de novo na conta ou verifique sua conexão.';
    }
  }
  if (error is FirebaseException) {
    final c = error.code.toLowerCase();
    if (c.contains('permission') || c.contains('denied')) {
      return 'Sem permissão para salvar. Saia e entre de novo na conta ou verifique sua conexão.';
    }
    if (c.contains('unavailable') || c.contains('network')) {
      return 'Serviço ou rede indisponível. Tente de novo em instantes.';
    }
    if (c.contains('disconnected')) {
      return 'Conexão com o servidor perdida. Verifique a internet e tente de novo.';
    }
    return 'Não foi possível salvar (${error.code}). Tente novamente.';
  }
  final s = error.toString();
  if (s.contains('permission-denied') || s.contains('PERMISSION_DENIED')) {
    return 'Sem permissão para salvar. Faça login novamente.';
  }
  return 'Erro ao salvar perfil. Tente novamente.';
}
