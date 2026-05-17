import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../models/provider_stats.dart';

class AcceptanceRateWidget extends StatelessWidget {
  final ProviderStats stats;

  const AcceptanceRateWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalBids;
    final accepted = stats.acceptedBids;
    final rate = total > 0 ? ((accepted / total) * 100).round() : 0;

    if (rate == 0 && total == 0) return const SizedBox.shrink();

    final Color barColor;
    final Color textColor;
    if (rate >= 60) {
      barColor = const Color(0xFF22C55E); // green500
      textColor = AppColors.green700;
    } else if (rate >= 30) {
      barColor = const Color(0xFFF59E0B); // amber500
      textColor = AppColors.amber700;
    } else {
      barColor = const Color(0xFFF87171); // red400
      textColor = const Color(0xFFDC2626); // red600
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Teklif Kabul Oranı',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600,
                ),
              ),
              Text(
                '%$rate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: rate / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
