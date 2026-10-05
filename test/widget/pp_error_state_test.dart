import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palace_pulse/shared/widgets/pp_error_state.dart';

void main() {
  testWidgets('PPErrorState mostra título e mensagem', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PPErrorState(
            title: 'Teste título',
            message: 'Teste mensagem',
          ),
        ),
      ),
    );

    expect(find.text('Teste título'), findsOneWidget);
    expect(find.text('Teste mensagem'), findsOneWidget);
  });

  testWidgets('PPErrorState com onRetry exibe botão', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PPErrorState(
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
