import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/badge_counts_provider.dart';
import '../../../core/theme/theme.dart';

class ProviderShell extends ConsumerWidget {
  final Widget child;

  const ProviderShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromPath(path);
    final counts = ref.watch(badgeCountsProvider).valueOrNull ?? const BadgeCounts();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _navigate(context, i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blue600.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.blue600),
            label: 'Anasayfa',
          ),
          NavigationDestination(
            icon: _badge(Icons.inbox_outlined, counts.unreadNotifications),
            selectedIcon: _badge(Icons.inbox, counts.unreadNotifications, color: AppColors.blue600),
            label: 'Talepler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work, color: AppColors.blue600),
            label: 'İşlerim',
          ),
          NavigationDestination(
            icon: _badge(Icons.local_offer_outlined, counts.pendingBids),
            selectedIcon: _badge(Icons.local_offer, counts.pendingBids, color: AppColors.blue600),
            label: 'Teklifler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.blue600),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  static Widget _badge(IconData icon, int count, {Color? color}) {
    final child = Icon(icon, color: color);
    if (count <= 0) return child;
    return Badge.count(
      count: count,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      child: child,
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
