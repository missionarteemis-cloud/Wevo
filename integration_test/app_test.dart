// Smoke di navigazione generato da flutter_dev.py setup.
// Personalizzami: aggiungi tap/scroll/asserzioni reali con i finder di Flutter
// (es. await tester.tap(find.text('Accedi')); await tester.pumpAndSettle();).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wevo_match_demo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: l\'app si avvia e renderizza', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 1));
    // ignora errori async (es. immagini di rete) nell'ambiente di test
    while (tester.takeException() != null) {}
    expect(find.byType(WidgetsApp), findsWidgets);
  });
}
