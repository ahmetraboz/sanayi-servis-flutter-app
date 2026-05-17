import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/theme.dart';
import '../models/provider_stats.dart';

class ProviderBanner extends ConsumerWidget {
  final ProviderStats? stats;

  const ProviderBanner({super.key, this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final companyName = user?.serviceProfile?['companyName'] as String? ?? user?.name ?? 'Servis Sağlayıcı';
    final city = user?.serviceProfile?['city'] as String?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue600, AppColors.blue800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -32,
            bottom: -32,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (city != null && city.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF93C5FD)),
                          const SizedBox(width: 2),
                          Text(city, style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13)),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      companyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (stats != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            '${stats!.averageRating} · ${stats!.totalReviews} değerlendirme',
                            style: const TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
