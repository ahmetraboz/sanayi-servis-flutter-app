import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/notification_polling_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/shared_pagination.dart';
import 'provider_notifications_notifier.dart';

const _filters = [
  {'key': 'all', 'label': 'Tümü'},
  {'key': 'bid', 'label': 'Teklifler'},
  {'key': 'request', 'label': 'Talepler'},
  {'key': 'review', 'label': 'Değerlendirmeler'},
  {'key': 'system', 'label': 'Sistem'},
];

class ProviderNotificationsScreen extends ConsumerStatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  ConsumerState<ProviderNotificationsScreen> createState() => _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState extends ConsumerState<ProviderNotificationsScreen> {
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(providerNotificationsProvider.notifier).markAllAsRead();
      if (mounted) ref.read(notificationPollingProvider.notifier).refresh();
    });
  }

  List<NotificationItem> _filtered(List<NotificationItem> all) {
    if (_activeFilter == 'all') return all;
    return all.where((n) => n.type.contains(_activeFilter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerNotificationsProvider);
    final notifier = ref.read(providerNotificationsProvider.notifier);
    final filtered = _filtered(state.notifications);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('Bildirimler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: Text('${state.unreadCount} okunmamış',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue600)),
              ),
            ],
          ],
        ),
        actions: [
          if (state.notifications.isNotEmpty) ...[
            if (state.unreadCount > 0)
              IconButton(
                icon: state.markingAll
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue600))
                    : const Icon(Icons.done_all_outlined, color: AppColors.gray600),
                tooltip: 'Tümünü okundu işaretle',
                onPressed: state.markingAll ? null : notifier.markAllAsRead,
              ),
            IconButton(
              icon: state.clearing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red700))
                  : const Icon(Icons.delete_outline, color: AppColors.red700),
              tooltip: 'Tümünü sil',
              onPressed: state.clearing ? null : () => _showClearConfirm(context, notifier),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (state.notifications.isNotEmpty) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isActive = _activeFilter == f['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeFilter = f['key']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.blue600 : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? AppColors.blue600 : AppColors.gray200),
                          ),
                          child: Text(
                            f['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isActive ? Colors.white : AppColors.gray600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.gray200),
          ],
          Expanded(
            child: RefreshIndicator(
              color: AppColors.blue600,
              onRefresh: () => notifier.fetchNotifications(page: 1),
              child: _buildBody(state, notifier, filtered),
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
    );
  }

  Widget _buildBody(ProviderNotificationsState state, ProviderNotificationsNotifier notifier, List<NotificationItem> filtered) {
    if (state.loading && state.notifications.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const _SkeletonItem(),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => notifier.fetchNotifications(),
              child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.blue600)),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.notifications_off_outlined, size: 32, color: AppColors.gray300),
            ),
            const SizedBox(height: 16),
            const Text('Bildiriminiz yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray700)),
            const SizedBox(height: 6),
            const Text('Yeni aktiviteler burada görünecek', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_outlined, size: 40, color: AppColors.gray300),
            SizedBox(height: 12),
            Text('Bu kategoride bildirim yok', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _NotificationCard(
        item: filtered[i],
        onTap: () {
          notifier.markAsRead(filtered[i].id);
          final link = filtered[i].link;
          if (link != null && link.isNotEmpty) {
            context.push(link);
          }
        },
      ),
    );
  }

  void _showClearConfirm(BuildContext context, ProviderNotificationsNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bildirimleri Sil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text('Tüm bildirimler kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: AppColors.gray500))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  static const _kMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} sa önce';
      if (diff.inDays < 7) return '${diff.inDays} gün önce';
      return '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  (IconData, Color, Color) _typeStyle(String type) => switch (type) {
    'bid' => (Icons.local_offer_outlined, AppColors.blue600, const Color(0xFFEFF6FF)),
    'review' || 'completion' => (Icons.star_outline, AppColors.yellow400, const Color(0xFFFEF9C3)),
    'info_request' || 'request' => (Icons.info_outline, AppColors.primary600, AppColors.green50),
    'update' => (Icons.update_outlined, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
    _ => (Icons.notifications_outlined, AppColors.gray500, AppColors.gray100),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = _typeStyle(item.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead ? AppColors.gray200 : AppColors.blue600.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.blue600, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (item.message != null && item.message!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(item.message!, style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 5),
                  Text(_fmtDate(item.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
        child: Row(
          children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 160, decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
