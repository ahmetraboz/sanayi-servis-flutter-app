import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../models/provider_stats.dart';

class ProviderStatCards extends StatelessWidget {
  final ProviderStats stats;

  const ProviderStatCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatConfig(
        label: 'Açık Talepler',
        value: '${stats.openRequests}',
        icon: Icons.inbox_outlined,
        iconColor: AppColors.blue600,
        bgColor: AppColors.info50,
      ),
      _StatConfig(
        label: 'Bekleyen Teklifler',
        value: '${stats.pendingBids}',
        icon: Icons.pending_outlined,
        iconColor: AppColors.amber600,
        bgColor: AppColors.amber50,
      ),
      _StatConfig(
        label: 'Kabul Edilen',
        value: '${stats.acceptedBids}',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.green700,
        bgColor: AppColors.green50,
      ),
      _StatConfig(
        label: 'Ortalama Puan',
        value: stats.averageRating,
        icon: Icons.star_outline,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((c) => _StatCard(config: c)).toList(),
    );
  }
}

class _StatConfig {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatConfig config;

  const _StatCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(config.icon, size: 18, color: config.iconColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                config.label,
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
