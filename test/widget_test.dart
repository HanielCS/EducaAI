import 'package:educaai/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test: Verifies that the app loads', (
    WidgetTester tester,
  ) async {
    // 1. Constrói o nosso app (EducaAIApp), e não o MyApp
    await tester.pumpWidget(const EducaAIApp());

    // 2. Aguarda o app carregar.
    // O Wrapper vai rodar e, como não estamos logados,
    // ele deve mostrar a LoginScreen.
    await tester.pumpAndSettle();

    // 3. Verifica se o nome do app aparece na tela de Login.
    // Usamos 'findsWidgets' porque o nome pode aparecer em mais de um lugar.
    expect(find.text('EducaAI'), findsWidgets);

    // 4. Verifica se o campo de E-mail está visível.
    expect(find.text('E-mail'), findsOneWidget);
  });
}
