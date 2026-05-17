import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../models/active_job.dart';

class ActiveJobsSection extends StatelessWidget {
  final List<ActiveJob> jobs;

  const ActiveJobsSection({super.key, required this.jobs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktif İşler',
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
        if (jobs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Center(
              child: Text(
                'Aktif iş bulunmuyor.',
                style: TextStyle(fontSize: 14, color: AppColors.gray400),
              ),
            ),
          )
        else
          ...jobs.map((job) => _JobCard(job: job)),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final ActiveJob job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusBg) = switch (job.status) {
      'in_progress' => ('Devam Ediyor', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      'accepted' => ('Kabul Edildi', const Color(0xFF059669), const Color(0xFFECFDF5)),
      _ => (job.status, AppColors.gray500, AppColors.gray100),
    };

    return GestureDetector(
      onTap: () => context.go('/provider/requests/${job.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.blue600.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.build_outlined, size: 20, color: AppColors.blue600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
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
                    job.vehicleInfo,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.customerName,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
