import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String testProviderEmail = 'qwe@gmail.com';
const String testProviderPassword = '123123';

// Servis app nav label'ları
const String navHome = 'Anasayfa';
const String navRequests = 'Talepler';
const String navJobs = 'İşlerim';
const String navBids = 'Teklifler';
const String navProfile = 'İşletmem';

Future<void> pumpFor(WidgetTester tester, {int seconds = 2}) async {
  for (int i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitForWidget(WidgetTester tester, Finder finder,
    {int timeoutSeconds = 10}) async {
  for (int i = 0; i < timeoutSeconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets,
      reason: '$timeoutSeconds saniye içinde bulunamadı');
}

Future<void> waitForText(WidgetTester tester, String text,
    {int timeoutSeconds = 10}) async {
  await waitForWidget(tester, find.textContaining(text),
      timeoutSeconds: timeoutSeconds);
}

/// Zaten login olduysa dashboard'a döner.
/// Servis app direkt /login ile başlar.
Future<void> loginWith(WidgetTester tester, String email, String password) async {
  await pumpFor(tester, seconds: 3);

  // Zaten login olmuş → 'Anasayfa' nav item'ı görünüyor
  if (find.text(navHome).evaluate().isNotEmpty) return;

  // Login form görünene kadar bekle
  await waitForWidget(tester, find.byKey(const Key('email_field')));

  await tester.enterText(find.byKey(const Key('email_field')), email);
  await tester.pump();
  await tester.enterText(find.byKey(const Key('password_field')), password);
  await tester.pump();
  await tester.tap(find.byKey(const Key('login_button')));
  await pumpFor(tester, seconds: 5);
}

Future<void> waitForDashboard(WidgetTester tester) async {
  await waitForText(tester, navHome);
}
