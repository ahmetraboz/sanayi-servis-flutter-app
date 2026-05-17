import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/router.dart';
import 'core/services/toast_service.dart';
import 'core/theme/theme.dart';

void main() {
  runApp(const ProviderScope(child: SanayiServisApp()));
}

class SanayiServisApp extends ConsumerWidget {
  const SanayiServisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Sanayi Servis',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
