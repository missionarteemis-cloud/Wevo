import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wevo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real flow smoke: demo login, discover, match overlay, matches, chat composer', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Accesso rapido demo'), findsOneWidget);
    await tester.tap(find.text('Accesso rapido demo'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Entra con account demo'), findsOneWidget);
    await tester.tap(find.text('Entra con account demo'));
    await tester.pumpAndSettle(const Duration(seconds: 6));

    while (tester.takeException() != null) {}

    expect(find.text('Discover'), findsWidgets);

    final likeButtons = find.byIcon(Icons.favorite);
    expect(likeButtons, findsWidgets);
    await tester.tap(likeButtons.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text("it's a match!"), findsOneWidget);
    expect(find.text('Inizia a chattare'), findsOneWidget);

    await tester.tap(find.text('Inizia a chattare'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Matches'), findsWidgets);
    expect(find.text('Scrivi un messaggio...'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Integration test ping');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Integration test ping'), findsOneWidget);
  });
}
