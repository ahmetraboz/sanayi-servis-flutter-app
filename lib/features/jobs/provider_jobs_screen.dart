import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/skeleton.dart';
import 'provider_jobs_notifier.dart';

class ProviderJobsScreen extends ConsumerWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerJobsProvider);
    final notifier = ref.read(providerJobsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const PageHeader(title: 'İşlerim'),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue600,
                onRefresh: notifier.fetchJobs,
                child: _buildBody(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProviderJobsState state) {
    if (state.loading) {
      return const _JobListSkeleton();
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (state.jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.work_outline, size: 32, color: AppColors.gray300),
            ),
            const SizedBox(height: 16),
            const Text('Henüz aktif işiniz yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Taleplere teklif verin ve müşteri kabulünden sonra burada görünecek',
                style: TextStyle(fontSize: 13, color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/provider/requests'),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Açık Taleplere Git'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.activeJobs.isNotEmpty) ...[
          _SectionHeader(
            dot: const _PulseDot(color: AppColors.blue600),
            label: 'Aktif İşler',
            count: state.activeJobs.length,
          ),
          const SizedBox(height: 10),
          ...state.activeJobs.map((job) => _ActiveJobCard(job: job)),
          const SizedBox(height: 20),
        ],
        if (state.pendingReviewJobs.isNotEmpty) ...[
          _SectionHeader(
            dot: const _PulseDot(color: AppColors.yellow400),
            label: 'Değerlendirme Bekliyor',
            count: state.pendingReviewJobs.length,
          ),
          const SizedBox(height: 10),
          ...state.pendingReviewJobs.map((job) => _PendingReviewCard(job: job)),
          const SizedBox(height: 20),
        ],
        if (state.completedJobs.isNotEmpty) ...[
          _SectionHeader(
            dot: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary600),
            label: 'Tamamlanan İşler',
            count: state.completedJobs.length,
          ),
          const SizedBox(height: 10),
          ...state.completedJobs.map((job) => _CompletedJobCard(job: job)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final Widget dot;
  final String label;
  final int count;

  const _SectionHeader({required this.dot, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        dot,
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray500, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _vehicleLabel(Map<String, dynamic> job) {
  final brand = job['vehicleBrand'] as String? ?? '';
  final model = job['vehicleModel'] as String? ?? '';
  final year = job['vehicleYear'];
  return '$brand $model${year != null ? ' ($year)' : ''}'.trim();
}

const _kMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

String _fmtDate(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return '';
  }
}

// ─── Active Job Card ──────────────────────────────────────────────────────────

class _ActiveJobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const _ActiveJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String? ?? '';
    final title = job['title'] as String? ?? '';
    final plate = job['vehiclePlate'] as String?;
    final customerName = job['customerName'] as String? ?? '';
    final customerPhone = job['customerPhone'] as String?;
    final updatedAt = job['updatedAt'] as String?;
    final urgency = job['urgencyLevel'] as String?;
    final isInProgress = status == 'in_progress';

    return GestureDetector(
      onTap: () => context.push('/provider/requests/${job['id']}?from=jobs'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
          boxShadow: [BoxShadow(color: AppColors.blue600.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.build_outlined, size: 20, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StatusBadge(status: status),
                            if (urgency == 'urgent' || urgency == 'critical') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(6)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_outlined, size: 12, color: AppColors.red700),
                                    SizedBox(width: 3),
                                    Text('Acil', style: TextStyle(fontSize: 11, color: AppColors.red700, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(
                          _vehicleLabel(job) + (plate != null && plate.isNotEmpty ? ' · $plate' : ''),
                          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                      if (customerPhone != null && customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(customerPhone, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                      ],
                      const SizedBox(height: 4),
                      Text(_fmtDate(updatedAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F7FF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isInProgress ? 'Güncelleme Ekle / Detay' : 'Detaya Git',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.blue600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Review Card ──────────────────────────────────────────────────────

class _PendingReviewCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const _PendingReviewCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final title = job['title'] as String? ?? '';
    final customerName = job['customerName'] as String? ?? '';
    final updatedAt = job['updatedAt'] as String?;

    return GestureDetector(
      onTap: () => context.push('/provider/requests/${job['id']}?from=jobs'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFEF9C3), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.star_outline, size: 20, color: AppColors.yellow400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFEF9C3), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Değerlendirme Bekliyor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amber600)),
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_vehicleLabel(job), style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                const SizedBox(height: 4),
                Text(_fmtDate(updatedAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Completed Job Card ───────────────────────────────────────────────────────

class _CompletedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const _CompletedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final title = job['title'] as String? ?? '';
    final updatedAt = job['updatedAt'] as String?;

    return GestureDetector(
      onTap: () => context.push('/provider/requests/${job['id']}?from=jobs'),
      child: Opacity(
        opacity: 0.72,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(5)),
                      child: const Text('Tamamlandı', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary600)),
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_vehicleLabel(job), style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                  ],
                ),
              ),
              Text(_fmtDate(updatedAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'accepted' => ('Kabul Edildi', AppColors.primary600, AppColors.green50),
      'in_progress' => ('Devam Ediyor', AppColors.blue600, const Color(0xFFEFF6FF)),
      _ => (status, AppColors.gray500, AppColors.gray100),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _JobListSkeleton extends StatelessWidget {
  const _JobListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(height: 40, width: 40, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 15, radius: 5),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 140, radius: 4),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                SkeletonBox(height: 24, width: 80, radius: 20),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(height: 12, width: 200, radius: 4),
          ],
        ),
      ),
    );
  }
}
