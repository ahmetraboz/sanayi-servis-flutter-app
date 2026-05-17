import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/shared_pagination.dart';
import 'provider_guest_bookings_notifier.dart';

class ProviderGuestBookingsScreen extends ConsumerWidget {
  const ProviderGuestBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerGuestBookingsProvider);
    final notifier = ref.read(providerGuestBookingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Misafir Rezervasyonlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: () => notifier.fetchBookings(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.blue600,
              onRefresh: () => notifier.fetchBookings(page: 1),
              child: _buildBody(context, state),
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

  Widget _buildBody(BuildContext context, ProviderGuestBookingsState state) {
    if (state.loading && state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2));
    }

    if (state.error != null && state.bookings.isEmpty) {
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

    if (state.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_outline, size: 32, color: AppColors.gray300),
            ),
            const SizedBox(height: 16),
            const Text('Misafir rezervasyonu yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray700)),
            const SizedBox(height: 6),
            const Text('Üye olmayan müşterilerin talepleri burada görünecek', style: TextStyle(fontSize: 13, color: AppColors.gray400), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _BookingCard(
        booking: state.bookings[i],
        onTap: () => context.push('/provider/guest-bookings/${state.bookings[i]['id']}'),
      ),
    );
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  static const _kMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  (String, Color, Color) _responseStyle(String? r) => switch (r) {
    'quoted' => ('Fiyat Verildi', AppColors.blue600, const Color(0xFFEFF6FF)),
    'rejected' => ('Reddedildi', AppColors.red700, AppColors.red50),
    _ => ('Yanıt Bekleniyor', AppColors.amber600, const Color(0xFFFEF9C3)),
  };

  (String, Color, Color) _bookingStatusStyle(String? s) => switch (s) {
    'pending' => ('Bekliyor', AppColors.gray500, AppColors.gray100),
    'accepted' => ('Kabul Edildi', AppColors.primary600, AppColors.green50),
    'in_progress' => ('Devam Ediyor', AppColors.blue600, const Color(0xFFEFF6FF)),
    'pending_review' => ('Değerlendirme Bekliyor', AppColors.amber600, const Color(0xFFFEF9C3)),
    'completed' => ('Tamamlandı', AppColors.primary600, AppColors.green50),
    _ => (s ?? '', AppColors.gray500, AppColors.gray100),
  };

  @override
  Widget build(BuildContext context) {
    final title = booking['title'] as String? ?? '';
    final name = booking['name'] as String? ?? '';
    final city = booking['city'] as String? ?? '';
    final brand = booking['brand'] as String? ?? '';
    final model = booking['model'] as String? ?? '';
    final year = booking['year'];
    final referenceCode = booking['referenceCode'] as String? ?? '';
    final createdAt = booking['createdAt'] as String?;
    final myResponse = booking['myResponse'] as String?;
    final bookingStatus = booking['status'] as String?;

    final vehicleLabel = '$brand $model${year != null ? ' ($year)' : ''}'.trim();
    final (responseLabel, responseColor, responseBg) = _responseStyle(myResponse);
    final (statusLabel, statusColor, statusBg) = _bookingStatusStyle(bookingStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Misafir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber600)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: responseBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(responseLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: responseColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(name, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                const SizedBox(width: 10),
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(city, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, size: 14, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(vehicleLabel, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#$referenceCode', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'monospace')),
                Text(_fmtDate(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
