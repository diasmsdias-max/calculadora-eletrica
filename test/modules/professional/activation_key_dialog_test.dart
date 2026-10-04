import 'package:calculadora_eletrica/modules/professional/activation_key_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns trimmed key without a dialog lifecycle assertion', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showActivationKeyDialog(context);
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' VIS-PRO-TEST ');
    await tester.tap(find.text('ATIVAR'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, 'VIS-PRO-TEST');
    expect(find.byType(ActivationKeyDialog), findsNothing);
  });

  testWidgets('cancel closes the dialog cleanly', (tester) async {
    String? result = 'unchanged';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showActivationKeyDialog(context);
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, isNull);
    expect(find.byType(ActivationKeyDialog), findsNothing);
  });
}
