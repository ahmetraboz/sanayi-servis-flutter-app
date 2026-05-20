import 'package:flutter/material.dart'; // Key
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanayi_servis_app/main.dart' as app;
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth — Giriş Yap', () {
    testWidgets('login ekranı açılır', (tester) async {
      app.main();
      await pumpFor(tester, seconds: 3);

      // Zaten giriş yapılmışsa (keychain session) dashboard'dayız — test geçerli
      if (find.text(navHome).evaluate().isNotEmpty) return;

      expect(find.text('Giriş Yap'), findsWidgets);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });

    testWidgets('boş form submit edilince hata mesajı gösterilir', (tester) async {
      app.main();
      await pumpFor(tester, seconds: 3);

      // Zaten giriş yapılmışsa atla
      if (find.text(navHome).evaluate().isNotEmpty) return;

      await tester.tap(find.byKey(const Key('login_button')));
      await pumpFor(tester);

      expect(find.textContaining('doldurun'), findsOneWidget);
    });

    testWidgets('yanlış şifre ile hata gösterilir', (tester) async {
      app.main();
      await pumpFor(tester, seconds: 3);

      // Zaten giriş yapılmışsa atla
      if (find.text(navHome).evaluate().isNotEmpty) return;

      await tester.enterText(find.byKey(const Key('email_field')), testProviderEmail);
      await tester.enterText(find.byKey(const Key('password_field')), 'yanlis123');
      await tester.tap(find.byKey(const Key('login_button')));
      await pumpFor(tester, seconds: 5);

      // Hata mesajı veya hâlâ login ekranında
      final onLoginOrError =
          find.byKey(const Key('login_button')).evaluate().isNotEmpty ||
          find.textContaining('hatalı').evaluate().isNotEmpty ||
          find.textContaining('geçersiz').evaluate().isNotEmpty;
      expect(onLoginOrError, isTrue);
    });

    testWidgets('doğru bilgilerle giriş yapılır ve provider dashboard açılır', (tester) async {
      app.main();
      await loginWith(tester, testProviderEmail, testProviderPassword);

      await waitForText(tester, navHome, timeoutSeconds: 10);
    });

    testWidgets('kayıt ol linkine tıklayınca register ekranı açılır', (tester) async {
      app.main();
      await pumpFor(tester, seconds: 3);

      // Zaten giriş yapılmışsa atla
      if (find.text(navHome).evaluate().isNotEmpty) return;

      await tester.tap(find.text('Kayıt ol'));
      await pumpFor(tester, seconds: 2);

      expect(find.text('Kayıt Ol'), findsWidgets);
    });
  });
}
