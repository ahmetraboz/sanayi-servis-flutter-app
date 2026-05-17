import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';

class ProviderRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const ProviderRequestCard({super.key, required this.request});

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const kMonths = [
        'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
      ];
      return '${dt.day} ${kMonths[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = request['title'] as String? ?? 'Başlıksız Talep';
    final description = request['description'] as String? ?? '';
    final brand = request['vehicleBrand'] as String? ?? '';
    final model = request['vehicleModel'] as String? ?? '';
    final year = request['vehicleYear'] as int?;
    final customerName = request['customerName'] as String? ?? 'Müşteri';
    final createdAt = request['createdAt'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/provider/requests/${request['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.gray400,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaItem(
                  icon: Icons.directions_car_outlined,
                  text: '$brand $model${year != null ? ' ($year)' : ''}'.trim(),
                ),
                _MetaItem(
                  icon: Icons.person_outline,
                  text: customerName,
                ),
                if (createdAt.isNotEmpty)
                  _MetaItem(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDate(createdAt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
