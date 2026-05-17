import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../models/open_request_preview.dart';

class RecentRequestsSection extends StatelessWidget {
  final List<OpenRequestPreview> requests;

  const RecentRequestsSection({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Yeni Talepler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
            ),
            TextButton(
              onPressed: () => context.go('/provider/requests'),
              child: const Text(
                'Tümünü Gör',
                style: TextStyle(fontSize: 13, color: AppColors.blue600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Center(
              child: Text(
                'Şu an yeni talep bulunmuyor.',
                style: TextStyle(fontSize: 14, color: AppColors.gray400),
              ),
            ),
          )
        else
          ...requests.map((req) => _RequestCard(request: req)),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final OpenRequestPreview request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final (urgencyLabel, urgencyColor) = switch (request.urgencyLevel) {
      'urgent' => ('Acil', AppColors.red700),
      'high' => ('Yüksek', AppColors.amber600),
      _ => ('Normal', AppColors.gray500),
    };

    return GestureDetector(
      onTap: () => context.go('/provider/requests/${request.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary600.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.car_repair_outlined, size: 20, color: AppColors.primary600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.vehicleInfo,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: urgencyColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          urgencyLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: urgencyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}
