import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import 'provider_dashboard_notifier.dart';
import 'widgets/active_jobs_section.dart';
import 'widgets/provider_stat_cards.dart';
import 'widgets/status_alert.dart';
import 'widgets/acceptance_rate_widget.dart';

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
            PageHeader(
              title: 'Anasayfa',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/provider/notifications'),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.gray600),
                  ),
                  const SizedBox(width: 16),
                  if (!state.loading)
                    GestureDetector(
                      onTap: notifier.load,
                      child: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
                    ),
                ],
              ),
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2),
      );
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
                const SizedBox(height: 16),
                AcceptanceRateWidget(stats: state.stats!),
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
