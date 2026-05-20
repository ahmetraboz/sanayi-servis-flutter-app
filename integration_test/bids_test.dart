import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanayi_servis_app/main.dart' as app;
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teklifler', () {
    testWidgets('Teklifler sayfası yüklenebilir', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navBids).first);
      await pumpFor(tester, seconds: 3);

      expect(find.textContaining('Teklif'), findsWidgets);
    });

    testWidgets("Tümü / Bekliyor tab'ları görünür", (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navBids).first);
      await pumpFor(tester, seconds: 3);

      expect(find.text('Tümü'), findsWidgets);
      expect(find.text('Bekliyor'), findsWidgets);
    });

    testWidgets("Bekliyor tab'ına geçilebilir", (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navBids).first);
      await pumpFor(tester, seconds: 2);

      await tester.tap(find.text('Bekliyor').first);
      await pumpFor(tester, seconds: 2);
    });

    testWidgets('Taleplere Git butonu açık talepler sayfasına yönlendirir', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navBids).first);
      await pumpFor(tester, seconds: 2);

      final goBtn = find.text('Taleplere Git');
      if (goBtn.evaluate().isNotEmpty) {
        await tester.tap(goBtn.first);
        await pumpFor(tester, seconds: 3);

        expect(
          find.textContaining('Talepler').evaluate().isNotEmpty ||
              find.textContaining('Açık').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });

  group('Açık Talepler', () {
    testWidgets('Açık talepler listesi yüklenebilir', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navRequests).first);
      await pumpFor(tester, seconds: 3);

      expect(
        find.textContaining('Talepler').evaluate().isNotEmpty ||
            find.textContaining('Açık').evaluate().isNotEmpty ||
            find.textContaining('Henüz').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
