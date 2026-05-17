import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';

class ProviderShell extends StatelessWidget {
  final Widget child;

  const ProviderShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromPath(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _navigate(context, i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blue600.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.blue600),
            label: 'Anasayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox, color: AppColors.blue600),
            label: 'Talepler',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work, color: AppColors.blue600),
            label: 'İşlerim',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer, color: AppColors.blue600),
            label: 'Teklifler',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.blue600),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith('/provider/requests')) return 1;
    if (path.startsWith('/provider/jobs')) return 2;
    if (path.startsWith('/provider/bids')) return 3;
    if (path.startsWith('/provider/profile')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int i) {
    const paths = [
      '/provider',
      '/provider/requests',
      '/provider/jobs',
      '/provider/bids',
      '/provider/profile',
    ];
    context.go(paths[i]);
  }
}
