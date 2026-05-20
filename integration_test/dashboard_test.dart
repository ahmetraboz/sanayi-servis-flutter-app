import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanayi_servis_app/main.dart' as app;
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Provider Dashboard', () {
    testWidgets('dashboard yüklendiğinde nav görünür', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      expect(find.text(navHome), findsWidgets);
      expect(find.text(navRequests), findsWidgets);
      expect(find.text(navBids), findsWidgets);
    });

    testWidgets('Talepler sekmesine geçilebilir', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navRequests).first);
      await pumpFor(tester, seconds: 3);

      expect(
        find.textContaining('Talepler').evaluate().isNotEmpty ||
            find.textContaining('Açık').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Teklifler sekmesi açılabilir', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navBids).first);
      await pumpFor(tester, seconds: 3);

      expect(find.textContaining('Teklif'), findsWidgets);
    });

    testWidgets('İşlerim sekmesi açılabilir', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navJobs).first);
      await pumpFor(tester, seconds: 3);

      expect(find.text(navJobs), findsWidgets);
    });

    testWidgets('İşletmem sekmesi açılabilir', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);
      await waitForDashboard(tester);

      await tester.tap(find.text(navProfile).first);
      await pumpFor(tester, seconds: 3);

      expect(find.text(navProfile), findsWidgets);
    });
  });
}
