import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/skeleton.dart';
import 'provider_dashboard_notifier.dart';
import 'widgets/active_jobs_section.dart';
import 'widgets/dashboard_banner_carousel.dart';
import 'widgets/provider_stat_cards.dart';
import 'widgets/status_alert.dart';


class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerDashboardProvider);
    final notifier = ref.read(providerDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const PageHeader(
              title: 'Anasayfa',
              action: NotificationIconButton(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue600,
                onRefresh: notifier.load,
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProviderDashboardState state) {
    if (state.loading && state.stats == null) {
      return const _DashboardSkeleton();
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const ProviderStatusAlert(),
              const SizedBox(height: 16),
              if (state.error != null && state.stats == null) ...[
                _ErrorCard(message: state.error!),
                const SizedBox(height: 16),
              ],
              const DashboardBannerCarousel(),
              const SizedBox(height: 20),
              if (state.stats != null) ...[
                const Text(
                  'İstatistikler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                ProviderStatCards(stats: state.stats!),
                const SizedBox(height: 24),
              ],
              if (state.activeJobs.isNotEmpty) ...[
                ActiveJobsSection(jobs: state.activeJobs),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.red700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.red700)),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Skeleton ───────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  static Widget _statCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBox(height: 36, width: 36, radius: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 22, width: 50, radius: 5),
                SizedBox(height: 6),
                SkeletonBox(height: 11, radius: 4),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 110, radius: 16),
          const SizedBox(height: 20),
          // 2×2 stat grid — matches ProviderStatCards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(4, (_) => _statCard()),
          ),
          const SizedBox(height: 24),
          // ActiveJobsSection skeleton
          const SkeletonBox(height: 14, width: 100, radius: 5),
          const SizedBox(height: 12),
          ...List.generate(2, (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
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
                    Expanded(child: SkeletonBox(height: 15, radius: 5)),
                    SizedBox(width: 40),
                    SkeletonBox(height: 22, width: 70, radius: 20),
                  ],
                ),
                SizedBox(height: 10),
                SkeletonBox(height: 12, width: 160, radius: 4),
                SizedBox(height: 6),
                SkeletonBox(height: 12, width: 100, radius: 4),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
