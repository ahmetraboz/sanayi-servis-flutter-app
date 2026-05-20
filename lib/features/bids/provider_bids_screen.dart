import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/date_picker_sheet.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/shared_pagination.dart';
import '../../../shared/widgets/skeleton.dart';
import 'provider_bids_notifier.dart';

const _tabs = [
  {'key': 'all', 'label': 'Tümü'},
  {'key': 'pending', 'label': 'Bekliyor'},
  {'key': 'accepted', 'label': 'Kabul Edildi'},
  {'key': 'rejected', 'label': 'Reddedildi'},
];

class ProviderBidsScreen extends ConsumerWidget {
  const ProviderBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerBidsProvider);
    final notifier = ref.read(providerBidsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const PageHeader(title: 'Tekliflerim'),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  _StatsRow(counts: state.counts),
                  const SizedBox(height: 12),
                  _TabBar(activeTab: state.activeTab, counts: state.counts, onTabChanged: notifier.onTabChanged),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray200),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue600,
                onRefresh: () => notifier.fetchBids(page: 1),
                child: _buildBody(context, state, notifier),
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

  Widget _buildBody(BuildContext context, ProviderBidsState state, ProviderBidsNotifier notifier) {
    if (state.loading && state.bids.isEmpty) {
      return const _BidListSkeleton();
    }

    if (state.error != null && state.bids.isEmpty) {
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
                  const SizedBox(height: 12),
                  Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => notifier.fetchBids(page: 1),
                    child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.blue600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state.bids.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: AppColors.gray300),
                  const SizedBox(height: 16),
                  Text(
                    state.activeTab == 'all' ? 'Henüz teklif vermediniz' : 'Bu kategoride teklif yok',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray700),
                  ),
                  if (state.activeTab == 'all') ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/provider/requests'),
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text('Taleplere Git', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.bids.length,
      itemBuilder: (ctx, i) => _BidCard(bid: state.bids[i]),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, int> counts;

  const _StatsRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(value: counts['all'] ?? 0, label: 'Toplam', valueColor: AppColors.gray900, borderColor: AppColors.gray200),
        const SizedBox(width: 6),
        _StatCell(value: counts['pending'] ?? 0, label: 'Bekliyor', valueColor: AppColors.yellow400, borderColor: const Color(0xFFFDE68A)),
        const SizedBox(width: 6),
        _StatCell(value: counts['accepted'] ?? 0, label: 'Kabul', valueColor: AppColors.primary600, borderColor: AppColors.emerald200),
        const SizedBox(width: 6),
        _StatCell(value: counts['rejected'] ?? 0, label: 'Reddedildi', valueColor: AppColors.red700, borderColor: AppColors.red100),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final int value;
  final String label;
  final Color valueColor;
  final Color borderColor;

  const _StatCell({required this.value, required this.label, required this.valueColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final String activeTab;
  final Map<String, int> counts;
  final void Function(String) onTabChanged;

  const _TabBar({required this.activeTab, required this.counts, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: _tabs.map((tab) {
          final key = tab['key']!;
          final isActive = activeTab == key;
          final count = counts[key] ?? 0;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        tab['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? AppColors.gray900 : AppColors.gray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.blue600.withValues(alpha: 0.1) : AppColors.gray200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppColors.blue600 : AppColors.gray500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Bid Card ─────────────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  final Map<String, dynamic> bid;

  const _BidCard({required this.bid});

  static const _kMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _fmtPrice(dynamic raw) {
    final val = double.tryParse('$raw') ?? 0;
    return '₺${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final bidStatus = bid['status'] as String? ?? '';
    final requestStatus = bid['requestStatus'] as String? ?? '';
    final title = bid['requestTitle'] as String? ?? '';
    final brand = bid['vehicleBrand'] as String? ?? '';
    final model = bid['vehicleModel'] as String? ?? '';
    final duration = bid['estimatedDuration'] as String?;
    final description = bid['description'] as String?;
    final proposedDate = bid['proposedDate'] as String?;
    final createdAt = bid['createdAt'] as String?;
    final price = bid['price'];
    final requestId = bid['requestId'];

    final priceVal = double.tryParse('$price') ?? 0.0;
    final isAccepted = bidStatus == 'accepted';
    final isRejected = bidStatus == 'rejected';

    return GestureDetector(
      onTap: () => context.push('/provider/requests/$requestId?from=bids'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAccepted
                ? const Color(0xFF86EFAC)
                : isRejected
                    ? AppColors.red100
                    : AppColors.gray200,
            width: isAccepted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Opacity(
          opacity: isRejected ? 0.65 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      priceVal == 0 ? 'Talebi Reddettiniz' : _fmtPrice(price),
                      style: TextStyle(
                        fontSize: priceVal == 0 ? 13 : 18,
                        fontWeight: FontWeight.bold,
                        color: priceVal == 0 ? AppColors.red700 : AppColors.blue600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MetaItem(icon: Icons.directions_car_outlined, text: '$brand $model'.trim()),
                    if (duration != null && duration.isNotEmpty)
                      _MetaItem(icon: Icons.schedule_outlined, text: duration),
                    if (createdAt != null)
                      _MetaItem(icon: Icons.calendar_today_outlined, text: _fmtDate(createdAt)),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (proposedDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6EE7B7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available_outlined, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          'Önerilen tarih: ${formatDateTr(proposedDate)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _BidStatusBadge(status: bidStatus),
                    const SizedBox(width: 6),
                    _RequestStatusBadge(status: requestStatus),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.gray300),
                  ],
                ),
              ],
            ),
          ),
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
        Icon(icon, size: 13, color: AppColors.gray400),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
      ],
    );
  }
}

class _BidStatusBadge extends StatelessWidget {
  final String status;

  const _BidStatusBadge({required this.status});

  static const _labels = {'pending': 'Bekliyor', 'accepted': 'Kabul Edildi', 'rejected': 'Reddedildi'};
  static const _colors = {'pending': AppColors.yellow400, 'accepted': AppColors.primary600, 'rejected': AppColors.red700};
  static const _bgs = {'pending': Color(0xFFFEF9C3), 'accepted': AppColors.green50, 'rejected': AppColors.red50};

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;
    final color = _colors[status] ?? AppColors.gray500;
    final bg = _bgs[status] ?? AppColors.gray100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  final String status;

  const _RequestStatusBadge({required this.status});

  static const _labels = {
    'open': 'Açık',
    'bidding': 'Teklifte',
    'info_requested': 'Bilgi Bekleniyor',
    'info_provided': 'Bilgi Geldi',
    'accepted': 'Kabul Edildi',
    'in_progress': 'Devam Ediyor',
    'pending_review': 'Değerlendirme',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal',
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
    );
  }
}

class _BidListSkeleton extends StatelessWidget {
  const _BidListSkeleton();

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 15, radius: 5)),
                SizedBox(width: 40),
                SkeletonBox(height: 22, width: 80, radius: 5),
              ],
            ),
            SizedBox(height: 10),
            SkeletonBox(height: 12, width: 200, radius: 4),
            SizedBox(height: 8),
            SkeletonBox(height: 12, width: 140, radius: 4),
            SizedBox(height: 12),
            Row(
              children: [
                SkeletonBox(height: 22, width: 90, radius: 6),
                SizedBox(width: 6),
                SkeletonBox(height: 22, width: 80, radius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
