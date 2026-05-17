import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

typedef _StatusConfig = ({Color bg, Color text, String label});

const _kStatusMap = <String, _StatusConfig>{
  'open': (bg: AppColors.info50, text: AppColors.blue700, label: 'Açık'),
  'bidding': (bg: AppColors.violet50, text: AppColors.violet700, label: 'Teklif Bekleniyor'),
  'info_requested': (bg: AppColors.amber50, text: AppColors.amber700, label: 'Bilgi Bekleniyor'),
  'accepted': (bg: AppColors.success50, text: AppColors.primary700, label: 'Onaylandı'),
  'in_progress': (bg: AppColors.info50, text: AppColors.blue700, label: 'Devam Ediyor'),
  'pending_review': (bg: AppColors.amber50, text: AppColors.amber700, label: 'Değerlendirme'),
  'completed': (bg: AppColors.green50, text: AppColors.green700, label: 'Tamamlandı'),
  'cancelled': (bg: AppColors.red50, text: AppColors.red700, label: 'İptal Edildi'),
};

enum StatusBadgeVariant { subtle, solid }

class StatusBadge extends StatelessWidget {
  final String status;
  final StatusBadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.status,
    this.variant = StatusBadgeVariant.subtle,
  });

  @override
  Widget build(BuildContext context) {
    final config = _kStatusMap[status] ??
        (bg: AppColors.gray100, text: AppColors.gray600, label: status);

    final bgColor = variant == StatusBadgeVariant.solid ? config.text : config.bg;
    final textColor = variant == StatusBadgeVariant.solid ? Colors.white : config.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
