import 'package:calculadora_eletrica/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app starts and opens every main destination', (tester) async {
    await tester.pumpWidget(const CalculadoraEletricaApp());
    await tester.pumpAndSettle();

    expect(find.text('BOECKER'), findsOneWidget);
    expect(find.text('VIS ELECTRICA'), findsOneWidget);

    const destinations = [
      'Motor Elétrico',
      'Transformador',
      'Motor × Transformador',
      'Levantamento de Cargas',
      'Dimensionamento de Cabos',
      'Queda de Tensão',
      'Meus Projetos',
    ];

    for (final destination in destinations) {
      await tester.tap(find.text(destination).first);
      await tester.pumpAndSettle();
      expect(find.text(destination), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsWidgets);
  });
}
