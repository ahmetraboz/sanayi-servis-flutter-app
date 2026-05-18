import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import 'provider_open_requests_notifier.dart';
import 'provider_request_detail_notifier.dart';

// ─── Category config ──────────────────────────────────────────────────────────

typedef _Cat = ({String label, Color bg, Color text, IconData icon});

const _categories = <String, _Cat>{
  'motor':    (label: 'Motor',       bg: Color(0xFFFEE2E2), text: Color(0xFFDC2626), icon: Icons.local_fire_department_outlined),
  'elektrik': (label: 'Elektrik',    bg: Color(0xFFFEF9C3), text: Color(0xFFCA8A04), icon: Icons.bolt_outlined),
  'fren':     (label: 'Fren',        bg: Color(0xFFFFEDD5), text: Color(0xFFEA580C), icon: Icons.do_not_disturb_on_outlined),
  'suspan':   (label: 'Süspansiyon', bg: Color(0xFFDBEAFE), text: Color(0xFF2563EB), icon: Icons.tune_outlined),
  'kaporta':  (label: 'Kaporta',     bg: Color(0xFFF3E8FF), text: Color(0xFF9333EA), icon: Icons.brush_outlined),
  'klima':    (label: 'Klima',       bg: Color(0xFFCFFAFE), text: Color(0xFF0891B2), icon: Icons.ac_unit_outlined),
  'lastik':   (label: 'Lastik',      bg: Color(0xFFF1F5F9), text: Color(0xFF475569), icon: Icons.tire_repair_outlined),
  'vites':    (label: 'Vites',       bg: Color(0xFFE0E7FF), text: Color(0xFF4F46E5), icon: Icons.settings_outlined),
  'egzoz':    (label: 'Egzoz',       bg: Color(0xFFD1FAE5), text: Color(0xFF059669), icon: Icons.cloud_outlined),
  'diger':    (label: 'Diğer',       bg: Color(0xFFF3F4F6), text: Color(0xFF6B7280), icon: Icons.help_outline),
};

typedef _Urg = ({String label, Color bg, Color text});

const _urgency = <String, _Urg>{
  'low':    (label: 'Acele Değil', bg: Color(0xFFDCFCE7), text: Color(0xFF16A34A)),
  'normal': (label: 'Normal',      bg: Color(0xFFFEF9C3), text: Color(0xFFCA8A04)),
  'urgent': (label: 'Acil',        bg: Color(0xFFFEE2E2), text: Color(0xFFDC2626)),
};

typedef _Stat = ({String label, Color bg, Color text});

const _statuses = <String, _Stat>{
  'open':           (label: 'Açık',                  bg: Color(0xFFDBEAFE), text: Color(0xFF2563EB)),
  'bidding':        (label: 'Teklif Alınıyor',        bg: Color(0xFFEDE9FE), text: Color(0xFF7C3AED)),
  'info_requested': (label: 'Bilgi Bekleniyor',       bg: Color(0xFFFEF9C3), text: Color(0xFFCA8A04)),
  'info_provided':  (label: 'Bilgi Verildi',          bg: Color(0xFFDCFCE7), text: Color(0xFF16A34A)),
  'accepted':       (label: 'Kabul Edildi',           bg: Color(0xFFDCFCE7), text: Color(0xFF16A34A)),
  'in_progress':    (label: 'İşlemde',                bg: Color(0xFFFEF9C3), text: Color(0xFFCA8A04)),
  'pending_review': (label: 'Değerlendirme Bekliyor', bg: Color(0xFFFEF9C3), text: Color(0xFFCA8A04)),
  'completed':      (label: 'Tamamlandı',             bg: Color(0xFFDCFCE7), text: Color(0xFF16A34A)),
  'cancelled':      (label: 'İptal',                  bg: Color(0xFFFEE2E2), text: Color(0xFFDC2626)),
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProviderRequestDetailScreen extends ConsumerWidget {
  final int requestId;

  const ProviderRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerRequestDetailProvider(requestId));
    final notifier = ref.read(providerRequestDetailProvider(requestId).notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Talep Detayı',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        iconTheme: const IconThemeData(color: AppColors.gray900),
        actions: [
          if (!state.loading && state.request != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: notifier.loadDetail,
              tooltip: 'Yenile',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildContent(context, state, notifier)),
            if (state.request != null && state.canBid)
              _ActionBar(state: state, notifier: notifier, requestId: requestId),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProviderRequestDetailState state,
    ProviderRequestDetailNotifier notifier,
  ) {
    if (state.request == null && state.error == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2),
      );
    }

    if (state.error != null && state.request == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                onPressed: notifier.loadDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final req = state.request!;

    return RefreshIndicator(
      color: AppColors.blue600,
      onRefresh: notifier.loadDetail,
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        _HeaderCard(request: req),
        const SizedBox(height: 12),
        if (state.isInfoRequested) ...[
          _StatusBanner(
            icon: Icons.access_time_rounded,
            color: const Color(0xFFCA8A04),
            bg: const Color(0xFFFEF9C3),
            title: 'Ek Bilgi Bekleniyor',
            subtitle: 'Müşteriye ek bilgi talebi gönderildi, yanıt bekleniyor.',
          ),
          const SizedBox(height: 12),
        ],
        if (state.isInfoProvided && state.additionalInfo != null) ...[
          _AdditionalInfoCard(info: state.additionalInfo!),
          const SizedBox(height: 12),
        ],
        _VehicleCard(request: req, imageUrl: state.vehicleImageUrl),
        const SizedBox(height: 12),
        _CustomerCard(request: req),
        if (req['aiDetectedPart'] != null) ...[
          const SizedBox(height: 12),
          _AiCard(request: req),
        ],
        if (state.updates.isNotEmpty || state.acceptedBid != null) ...[
          const SizedBox(height: 12),
          _JobLogCard(updates: state.updates),
        ],
        if (state.isPendingReview) ...[
          const SizedBox(height: 12),
          _StatusBanner(
            icon: Icons.star_outline_rounded,
            color: const Color(0xFFCA8A04),
            bg: const Color(0xFFFEF9C3),
            title: 'Değerlendirme Bekleniyor',
            subtitle: 'İşi tamamladınız. Müşteri değerlendirmesini bekliyorsunuz.',
          ),
        ],
        if (state.isCompleted) ...[
          const SizedBox(height: 12),
          _StatusBanner(
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFDCFCE7),
            title: 'Talep Tamamlandı',
            subtitle: 'Müşteri değerlendirmesini yaptı. Bu talep başarıyla tamamlandı.',
          ),
        ],
      ],
      ),
    );
  }
}

// ─── Header card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _HeaderCard({required this.request});

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = request['title'] as String? ?? 'Başlıksız Talep';
    final description = request['description'] as String? ?? '';
    final category = request['problemCategory'] as String?;
    final urgency = request['urgencyLevel'] as String?;
    final status = request['status'] as String?;
    final createdAt = request['createdAt'] as String?;
    final imageUrl = request['imageUrl'] as String?;

    final cat = category != null ? _categories[category] : null;
    final urg = urgency != null ? _urgency[urgency] : null;
    final stat = status != null ? _statuses[status] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                    height: 1.3,
                  ),
                ),
              ),
              if (createdAt != null && createdAt.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (cat != null) _SmallBadge(label: cat.label, bg: cat.bg, text: cat.text, icon: cat.icon),
              if (urg != null) _SmallBadge(label: urg.label, bg: urg.bg, text: urg.text),
              if (stat != null) _SmallBadge(label: stat.label, bg: stat.bg, text: stat.text),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.5),
            ),
          ],
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Vehicle card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String? imageUrl;
  const _VehicleCard({required this.request, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final brand = request['vehicleBrand'] as String? ?? '';
    final model = request['vehicleModel'] as String? ?? '';
    final year = request['vehicleYear'] as int?;
    final plate = request['vehiclePlate'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_outlined, size: 16, color: AppColors.primary600),
              const SizedBox(width: 6),
              const Text(
                'Araç Bilgileri',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Icon(Icons.directions_car_rounded, size: 32, color: AppColors.gray300),
                        )
                      : const Icon(Icons.directions_car_rounded, size: 32, color: AppColors.gray300),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$brand $model',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (year != null) ...[
                          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.gray400),
                          const SizedBox(width: 3),
                          Text(
                            '$year Model',
                            style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                          ),
                        ],
                        if (year != null && plate != null) const SizedBox(width: 10),
                        if (plate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.gray300),
                            ),
                            child: Text(
                              plate,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Customer card ────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _CustomerCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final name = request['customerName'] as String? ?? 'Müşteri';
    final phone = request['customerPhone'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.primary600),
              const SizedBox(width: 6),
              const Text(
                'Müşteri Bilgileri',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary600.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    if (phone != null)
                      Text(
                        phone,
                        style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                      ),
                  ],
                ),
              ),
              if (phone != null)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'Ara',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Additional info card ─────────────────────────────────────────────────────

class _AdditionalInfoCard extends StatelessWidget {
  final Map<String, dynamic> info;
  const _AdditionalInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, Color color, String label, String value})>[];
    if (info['engineDisplacement'] != null) {
      items.add((icon: Icons.settings_outlined, color: AppColors.gray500, label: 'Motor Hacmi', value: info['engineDisplacement'].toString()));
    }
    if (info['fuelType'] != null) {
      items.add((icon: Icons.local_fire_department_outlined, color: const Color(0xFFF97316), label: 'Yakıt Türü', value: info['fuelType'].toString()));
    }
    if (info['transmissionType'] != null) {
      items.add((icon: Icons.tune_outlined, color: const Color(0xFF3B82F6), label: 'Vites Tipi', value: info['transmissionType'].toString()));
    }
    if (info['bodyType'] != null) {
      items.add((icon: Icons.directions_car_outlined, color: AppColors.gray500, label: 'Kasa Tipi', value: info['bodyType'].toString()));
    }
    if (info['mileage'] != null) {
      items.add((icon: Icons.speed_outlined, color: AppColors.gray500, label: 'Kilometre', value: '${info['mileage']} km'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 6),
                Text(
                  'Müşteri Ek Bilgileri',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 16, color: item.color),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                        Text(item.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI card ──────────────────────────────────────────────────────────────────

class _AiCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _AiCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final part = request['aiDetectedPart'] as String? ?? '';
    final confidence = request['aiConfidence'] as num?;
    final pct = confidence != null ? ' (%${(confidence * 100).round()} güven)' : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.memory_outlined, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yapay Zeka Tespiti',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$part$pct',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Job log card ─────────────────────────────────────────────────────────────

class _JobLogCard extends StatelessWidget {
  final List<Map<String, dynamic>> updates;
  const _JobLogCard({required this.updates});

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  ({Color bg, Color border, Color text, Color headerBg, IconData icon, String label}) _typeConfig(String type) {
    if (type == 'completed') {
      return (
        bg: const Color(0xFFDCFCE7),
        border: const Color(0xFF6EE7B7),
        text: const Color(0xFF059669),
        headerBg: const Color(0xFFF0FDF4),
        icon: Icons.check_circle_outline_rounded,
        label: 'Tamamlandı',
      );
    }
    if (type == 'delay') {
      return (
        bg: const Color(0xFFFFEDD5),
        border: const Color(0xFFFDBA74),
        text: const Color(0xFFEA580C),
        headerBg: const Color(0xFFFFF7ED),
        icon: Icons.access_time_rounded,
        label: 'Gecikme',
      );
    }
    return (
      bg: const Color(0xFFDBEAFE),
      border: const Color(0xFF93C5FD),
      text: const Color(0xFF2563EB),
      headerBg: const Color(0xFFEFF6FF),
      icon: Icons.sync_rounded,
      label: 'Güncelleme',
    );
  }

  String _formatCost(dynamic val) {
    if (val == null) return '';
    final num = double.tryParse(val.toString()) ?? 0;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.list_alt_outlined, size: 16, color: AppColors.primary600),
                const SizedBox(width: 6),
                const Text(
                  'İş Günlüğü',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray100),
          if (updates.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Henüz güncelleme eklenmedi', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(updates.length, (i) {
                  final update = updates[i];
                  final type = update['updateType'] as String? ?? 'progress';
                  final cfg = _typeConfig(type);
                  final desc = update['description'] as String? ?? '';
                  final parts = update['partsUsed'] as String?;
                  final laborCost = update['laborCost'];
                  final partsCost = update['partsCost'];
                  final totalCost = update['totalCost'];
                  final createdAt = update['createdAt'] as String?;
                  final isLast = i == updates.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cfg.bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: cfg.border, width: 1.5),
                            ),
                            child: Icon(cfg.icon, size: 16, color: cfg.text),
                          ),
                          if (!isLast)
                            Container(width: 1.5, height: 24, color: AppColors.gray200),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cfg.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cfg.headerBg,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(cfg.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cfg.text)),
                                      const Spacer(),
                                      Text(_formatDate(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.4)),
                                      if (parts != null && parts.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.build_outlined, size: 13, color: AppColors.gray400),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Kullanılan Parçalar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray500)),
                                                  Text(parts, style: const TextStyle(fontSize: 12, color: AppColors.gray700)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (totalCost != null || laborCost != null || partsCost != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (laborCost != null)
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(8)),
                                                  child: Column(
                                                    children: [
                                                      const Text('İşçilik', style: TextStyle(fontSize: 10, color: AppColors.gray400)),
                                                      Text('${_formatCost(laborCost)} ₺', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            if (laborCost != null && partsCost != null) const SizedBox(width: 6),
                                            if (partsCost != null)
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(8)),
                                                  child: Column(
                                                    children: [
                                                      const Text('Parça', style: TextStyle(fontSize: 10, color: AppColors.gray400)),
                                                      Text('${_formatCost(partsCost)} ₺', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            if ((laborCost != null || partsCost != null) && totalCost != null) const SizedBox(width: 6),
                                            if (totalCost != null)
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF0FDF4),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFF6EE7B7)),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      const Text('Toplam', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
                                                      Text('${_formatCost(totalCost)} ₺', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small badge ──────────────────────────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  final IconData? icon;

  const _SmallBadge({required this.label, required this.bg, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text)),
        ],
      ),
    );
  }
}

// ─── Action bar ───────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  final ProviderRequestDetailState state;
  final ProviderRequestDetailNotifier notifier;
  final int requestId;

  const _ActionBar({required this.state, required this.notifier, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = state.submittingBid || state.dismissing || state.requestingInfo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: busy ? null : () => _confirmDismiss(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: state.dismissing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 6),
                        Text('Reddet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 8),
          if (state.canRequestInfo) ...[
            Expanded(
              child: GestureDetector(
                onTap: busy ? null : () => _showInfoSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.gray700),
                        SizedBox(width: 6),
                        Text('Ek Bilgi İste', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: GestureDetector(
              onTap: busy ? null : () => _showBidSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Teklif Ver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDismiss(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.cancel_outlined, size: 24, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Talebi Reddet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu talep listenizden kaldırılacak. Müşteri bilgilendirilmeyecek.',
              style: TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gray300),
                      foregroundColor: AppColors.gray700,
                    ),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Evet, Reddet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await notifier.dismissRequest();
      if (ok && context.mounted) {
        ref.invalidate(providerOpenRequestsProvider);
        context.pop();
      }
    }
  }

  Future<void> _showBidSheet(BuildContext context) async {
    await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BidSheet(notifier: notifier),
    );
  }

  Future<void> _showInfoSheet(BuildContext context) async {
    await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoRequestSheet(notifier: notifier),
    );
  }
}

// ─── Bid bottom sheet ─────────────────────────────────────────────────────────

class _BidSheet extends StatefulWidget {
  final ProviderRequestDetailNotifier notifier;
  const _BidSheet({required this.notifier});

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedDuration = '';
  bool _submitting = false;

  static const _durations = ['1 saat', '2-3 saat', 'Yarım gün', '1 gün', '2-3 gün', '1 hafta'];

  bool get _isValid {
    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    return price != null && price > 0;
  }

  Future<void> _submit() async {
    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null || price <= 0) return;

    setState(() => _submitting = true);
    final ok = await widget.notifier.submitBid(
      price: price,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      estimatedDuration: _selectedDuration.isEmpty ? null : _selectedDuration,
    );
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teklifiniz gönderildi'), backgroundColor: Color(0xFF16A34A)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teklif gönderilemedi'), backgroundColor: Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Teklif Ver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Teklif Fiyatı *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gray900),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: const TextStyle(color: AppColors.gray300, fontWeight: FontWeight.w400, fontSize: 22),
                      suffixText: '₺',
                      suffixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.gray400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  const Text('KDV dahil toplam tutar', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                  const SizedBox(height: 16),
                  const Text('Tahmini Süre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _durations.map((d) {
                      final active = _selectedDuration == d;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDuration = active ? '' : d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary600 : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: active ? AppColors.primary600 : AppColors.gray300),
                          ),
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: active ? Colors.white : AppColors.gray600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kapsam & Açıklama', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Yapılacak işlemleri, kullanılacak parçaları ve garantiyi açıklayın...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600, width: 1.5)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gray300),
                      foregroundColor: AppColors.gray600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting || !_isValid ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.gray200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Teklif Gönder', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info request bottom sheet ────────────────────────────────────────────────

class _InfoRequestSheet extends StatefulWidget {
  final ProviderRequestDetailNotifier notifier;
  const _InfoRequestSheet({required this.notifier});

  @override
  State<_InfoRequestSheet> createState() => _InfoRequestSheetState();
}

class _InfoRequestSheetState extends State<_InfoRequestSheet> {
  bool _engineDisplacement = false;
  bool _fuelType = false;
  bool _transmissionType = false;
  bool _bodyType = false;
  bool _mileage = false;
  final _notesController = TextEditingController();
  bool _submitting = false;

  bool get _isValid => _engineDisplacement || _fuelType || _transmissionType || _bodyType || _mileage || _notesController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await widget.notifier.requestInfo({
      if (_engineDisplacement) 'engineDisplacement': true,
      if (_fuelType) 'fuelType': true,
      if (_transmissionType) 'transmissionType': true,
      if (_bodyType) 'bodyType': true,
      if (_mileage) 'mileage': true,
      if (_notesController.text.trim().isNotEmpty) 'additionalNotes': _notesController.text.trim(),
    });
    if (mounted) {
      setState(() => _submitting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Ek bilgi talebi gönderildi' : 'İşlem başarısız'),
          backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Widget _checkRow(String label, bool value, void Function(bool) onChanged) {
    return InkWell(
      onTap: () => setState(() => onChanged(!value)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: value ? AppColors.primary600 : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: value ? AppColors.primary600 : AppColors.gray300, width: 1.5),
              ),
              child: value ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray900)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Ek Bilgi İste', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                const SizedBox(height: 4),
                const Text('Müşteriden istediğiniz bilgileri seçin', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.gray100),
                  _checkRow('Motor Hacmi', _engineDisplacement, (v) => _engineDisplacement = v),
                  const Divider(height: 1, color: AppColors.gray100),
                  _checkRow('Yakıt Türü', _fuelType, (v) => _fuelType = v),
                  const Divider(height: 1, color: AppColors.gray100),
                  _checkRow('Vites Tipi', _transmissionType, (v) => _transmissionType = v),
                  const Divider(height: 1, color: AppColors.gray100),
                  _checkRow('Kasa Tipi', _bodyType, (v) => _bodyType = v),
                  const Divider(height: 1, color: AppColors.gray100),
                  _checkRow('Kilometre', _mileage, (v) => _mileage = v),
                  const Divider(height: 1, color: AppColors.gray100),
                  const SizedBox(height: 14),
                  const Text('Ek Notlar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Müşteriye iletmek istediğiniz ek notlar...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600, width: 1.5)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gray300),
                      foregroundColor: AppColors.gray600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting || !_isValid ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.gray200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Gönder', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
