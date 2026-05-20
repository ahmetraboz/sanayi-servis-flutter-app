import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/shared_pagination.dart';
import '../../../shared/widgets/skeleton.dart';
import 'provider_open_requests_notifier.dart';
import 'widgets/provider_request_card.dart';

typedef _CategoryFilter = ({String key, String label, IconData icon, Color color});

const _urgencyFilters = <_CategoryFilter>[
  (key: 'all',    label: 'Her Öncelik', icon: Icons.filter_list_rounded,          color: Color(0xFF6B7280)),
  (key: 'urgent', label: 'Acil',        icon: Icons.warning_amber_rounded,        color: Color(0xFFDC2626)),
  (key: 'normal', label: 'Normal',      icon: Icons.radio_button_checked_outlined, color: Color(0xFF2563EB)),
  (key: 'low',    label: 'Acele Değil', icon: Icons.remove_circle_outline,        color: Color(0xFF059669)),
];

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
    final notifier = ref.watch(providerOpenRequestsProvider.notifier);

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
            _FilterBar(
              activeCategory: state.activeCategory,
              activeUrgency: state.activeUrgency,
              onCategoryChanged: notifier.onCategoryChanged,
              onUrgencyChanged: notifier.onUrgencyChanged,
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Center(
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
            ),
          ),
        ],
      );
    }

    if (state.requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Center(
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
            ),
          ),
        ],
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

// ─── Filter Bar (two pills) ───────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String activeCategory;
  final String activeUrgency;
  final void Function(String) onCategoryChanged;
  final void Function(String) onUrgencyChanged;

  const _FilterBar({
    required this.activeCategory,
    required this.activeUrgency,
    required this.onCategoryChanged,
    required this.onUrgencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _Pill(
            label: 'Öncelik',
            filters: _urgencyFilters,
            activeKey: activeUrgency,
            onChanged: onUrgencyChanged,
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Kategori',
            filters: _categoryFilters,
            activeKey: activeCategory,
            onChanged: onCategoryChanged,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final List<_CategoryFilter> filters;
  final String activeKey;
  final void Function(String) onChanged;

  const _Pill({
    required this.label,
    required this.filters,
    required this.activeKey,
    required this.onChanged,
  });

  bool get _isActive => activeKey != 'all';

  _CategoryFilter get _active => filters.firstWhere(
        (f) => f.key == activeKey,
        orElse: () => filters.first,
      );

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _PickerSheet(
        title: label,
        filters: filters,
        activeKey: activeKey,
        onChanged: onChanged,
        onDone: () => Navigator.of(sheetCtx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _isActive ? _active.color : AppColors.gray500;

    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isActive ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isActive ? color.withValues(alpha: 0.4) : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isActive)
              Icon(_active.icon, size: 14, color: color)
            else
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.gray400),
            const SizedBox(width: 5),
            Text(
              _isActive ? _active.label : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: _isActive ? FontWeight.w600 : FontWeight.w500,
                color: _isActive ? color : AppColors.gray600,
              ),
            ),
            if (_isActive) ...[
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () => onChanged('all'),
                child: Icon(Icons.close_rounded, size: 14, color: color),
              ),
            ] else ...[
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.gray400),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Picker Sheet ─────────────────────────────────────────────────────────────

class _PickerSheet extends StatefulWidget {
  final String title;
  final List<_CategoryFilter> filters;
  final String activeKey;
  final void Function(String) onChanged;
  final VoidCallback onDone;

  const _PickerSheet({
    required this.title,
    required this.filters,
    required this.activeKey,
    required this.onChanged,
    required this.onDone,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.activeKey;
  }

  void _pick(String key) {
    setState(() => _selected = key);
    widget.onChanged(key);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                GestureDetector(
                  onTap: widget.onDone,
                  child: const Text('Tamam', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...widget.filters.map((f) => _FilterRow(
                    filter: f,
                    isActive: _selected == f.key,
                    onTap: () => _pick(f.key),
                  )),
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

class _FilterRow extends StatelessWidget {
  final _CategoryFilter filter;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterRow({required this.filter, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: filter.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(filter.icon, size: 18, color: filter.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? filter.color : AppColors.gray700,
                ),
              ),
            ),
            if (isActive) Icon(Icons.check_rounded, size: 18, color: filter.color),
          ],
        ),
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
