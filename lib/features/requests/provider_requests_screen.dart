import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/shared_pagination.dart';
import '../../../shared/widgets/skeleton.dart';
import 'provider_open_requests_notifier.dart';
import 'widgets/provider_request_card.dart';

typedef _CategoryFilter = ({String key, String label, IconData icon, Color color});

const _categoryFilters = <_CategoryFilter>[
  (key: 'all',      label: 'Tüm Kategoriler', icon: Icons.list_alt_outlined,              color: Color(0xFF6B7280)),
  (key: 'motor',    label: 'Motor',            icon: Icons.local_fire_department_outlined, color: Color(0xFFDC2626)),
  (key: 'elektrik', label: 'Elektrik',         icon: Icons.bolt_outlined,                 color: Color(0xFFCA8A04)),
  (key: 'fren',     label: 'Fren',             icon: Icons.do_not_disturb_on_outlined,    color: Color(0xFFEA580C)),
  (key: 'suspan',   label: 'Süspansiyon',      icon: Icons.tune_outlined,                 color: Color(0xFF2563EB)),
  (key: 'kaporta',  label: 'Kaporta',          icon: Icons.brush_outlined,                color: Color(0xFF9333EA)),
  (key: 'klima',    label: 'Klima',            icon: Icons.ac_unit_outlined,              color: Color(0xFF0891B2)),
  (key: 'lastik',   label: 'Lastik',           icon: Icons.tire_repair_outlined,          color: Color(0xFF475569)),
  (key: 'vites',    label: 'Vites',            icon: Icons.settings_outlined,             color: Color(0xFF4F46E5)),
  (key: 'egzoz',    label: 'Egzoz',            icon: Icons.cloud_outlined,                color: Color(0xFF059669)),
  (key: 'diger',    label: 'Diğer',            icon: Icons.help_outline,                  color: Color(0xFF6B7280)),
];

class ProviderRequestsScreen extends ConsumerWidget {
  const ProviderRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerOpenRequestsProvider);
    final notifier = ref.read(providerOpenRequestsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Açık Talepler',
              action: state.total > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${state.total} talep',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary700,
                        ),
                      ),
                    )
                  : null,
            ),
            _CategoryFilterPill(
              activeCategory: state.activeCategory,
              onChanged: notifier.onCategoryChanged,
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.blue600,
              onRefresh: () => notifier.fetchRequests(page: 1),
              child: _buildBody(state, notifier),
            ),
          ),
          if (state.totalPages > 1)
            SharedPagination(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              total: state.total,
              onPrevious: state.currentPage > 1 ? notifier.previousPage : null,
              onNext: state.currentPage < state.totalPages ? notifier.nextPage : null,
            ),
        ],
      ),
    ),
  );
  }

  Widget _buildBody(ProviderOpenRequestsState state, ProviderOpenRequestsNotifier notifier) {
    if (state.loading && state.requests.isEmpty) {
      return const _RequestListSkeleton();
    }

    if (state.error != null && state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.fetchRequests(page: 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              state.activeCategory == 'all' ? 'Açık talep yok' : 'Bu kategoride talep bulunamadı',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.activeCategory == 'all'
                  ? 'Şu an için size yönlendirilmiş açık servis talebi bulunmuyor.'
                  : 'Farklı bir kategori filtresi deneyin.',
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: state.requests.length,
          itemBuilder: (context, index) {
            final request = state.requests[index] as Map<String, dynamic>;
            return ProviderRequestCard(request: request);
          },
        ),
        if (state.loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: AppColors.blue600,
              backgroundColor: AppColors.gray100,
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}

// ─── Filter Pill ──────────────────────────────────────────────────────────────

class _CategoryFilterPill extends StatelessWidget {
  final String activeCategory;
  final void Function(String) onChanged;

  const _CategoryFilterPill({required this.activeCategory, required this.onChanged});

  _CategoryFilter get _active => _categoryFilters.firstWhere(
        (f) => f.key == activeCategory,
        orElse: () => _categoryFilters.first,
      );

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryFilterSheet(
        activeCategory: activeCategory,
        onChanged: (val) {
          Navigator.of(context).pop();
          onChanged(val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final isFiltered = activeCategory != 'all';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isFiltered) ...[
            GestureDetector(
              onTap: () => onChanged('all'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.gray400),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => _showSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isFiltered ? active.color.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFiltered ? active.color.withValues(alpha: 0.4) : AppColors.gray200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: isFiltered ? active.color : AppColors.gray500),
                  const SizedBox(width: 6),
                  Text(
                    isFiltered ? active.label : 'Kategori',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isFiltered ? active.color : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isFiltered ? active.color : AppColors.gray400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  final String activeCategory;
  final void Function(String) onChanged;

  const _CategoryFilterSheet({required this.activeCategory, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kategori Filtrele',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ..._categoryFilters.map((f) {
                    final isActive = activeCategory == f.key;
                    return InkWell(
                      onTap: () => onChanged(f.key),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: f.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(f.icon, size: 18, color: f.color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? f.color : AppColors.gray700,
                                ),
                              ),
                            ),
                            if (isActive) Icon(Icons.check_rounded, size: 18, color: f.color),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: bottomPad + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestListSkeleton extends StatelessWidget {
  const _RequestListSkeleton();

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
                Expanded(child: SkeletonBox(height: 15, radius: 5)),
                SizedBox(width: 40),
                SkeletonBox(height: 22, width: 70, radius: 5),
              ],
            ),
            SizedBox(height: 10),
            SkeletonBox(height: 12, width: 180, radius: 4),
            SizedBox(height: 8),
            Row(
              children: [
                SkeletonBox(height: 22, width: 80, radius: 20),
                SizedBox(width: 8),
                SkeletonBox(height: 22, width: 70, radius: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
