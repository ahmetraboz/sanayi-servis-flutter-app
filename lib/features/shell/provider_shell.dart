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

    final bottomPad = MediaQuery.of(context).padding.bottom;
    // pill content (55px) + top margin (8px) + bottom margin (12px) = 75px above safe area
    const double navContentHeight = 75;

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad + navContentHeight),
            child: child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBar(
              selectedIndex: selectedIndex,
              counts: counts,
              onTap: (i) => _navigate(context, i),
            ),
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

// ─── Floating Nav Bar ─────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final BadgeCounts counts;
  final void Function(int) onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.counts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: [
              Expanded(child: _NavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Anasayfa',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              )),
              Expanded(child: _NavItem(
                icon: Icons.inbox_outlined,
                selectedIcon: Icons.inbox_rounded,
                label: 'Talepler',
                isSelected: selectedIndex == 1,
                badge: counts.unreadNotifications,
                onTap: () => onTap(1),
              )),
              Expanded(child: _NavItem(
                icon: Icons.work_outline_rounded,
                selectedIcon: Icons.work_rounded,
                label: 'İşlerim',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              )),
              Expanded(child: _NavItem(
                icon: Icons.local_offer_outlined,
                selectedIcon: Icons.local_offer_rounded,
                label: 'Teklifler',
                isSelected: selectedIndex == 3,
                badge: counts.pendingBids,
                onTap: () => onTap(3),
              )),
              Expanded(child: _NavItem(
                icon: Icons.store_outlined,
                selectedIcon: Icons.store_rounded,
                label: 'İşletmem',
                isSelected: selectedIndex == 4,
                onTap: () => onTap(4),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.blue600 : AppColors.gray400;

    Widget iconWidget = Icon(
      isSelected ? selectedIcon : icon,
      size: 22,
      color: color,
    );

    if (badge > 0) {
      iconWidget = Badge.count(
        count: badge,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue600.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
