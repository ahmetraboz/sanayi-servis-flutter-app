import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, size: 20, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text(
                'Hızlı İşlemler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _ActionCard(
                icon: Icons.search,
                label: 'Talepleri Gör',
                color: const Color(0xFF3B82F6), // blue500
                bgColor: const Color(0xFFEFF6FF), // blue50
                onTap: () => context.go('/provider/requests'),
              ),
              _ActionCard(
                icon: Icons.payments_outlined,
                label: 'Tekliflerim',
                color: const Color(0xFFF59E0B), // amber500
                bgColor: AppColors.amber50,
                onTap: () => context.go('/provider/bids'),
              ),
              _ActionCard(
                icon: Icons.work_outline,
                label: 'İşlerim',
                color: const Color(0xFF22C55E), // green500
                bgColor: AppColors.green50,
                onTap: () => context.go('/provider/jobs'),
              ),
              _ActionCard(
                icon: Icons.storefront_outlined,
                label: 'Profil',
                color: const Color(0xFF8B5CF6), // Violet 500
                bgColor: const Color(0xFFF5F3FF), // Violet 50
                onTap: () => context.go('/provider/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
