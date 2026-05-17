import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import 'provider_request_detail_notifier.dart';

class ProviderRequestDetailScreen extends ConsumerStatefulWidget {
  final int requestId;

  const ProviderRequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<ProviderRequestDetailScreen> createState() => _ProviderRequestDetailScreenState();
}

class _ProviderRequestDetailScreenState extends ConsumerState<ProviderRequestDetailScreen> {
  bool _showBidForm = false;
  bool _showInfoRequestForm = false;
  bool _showUpdateForm = false;
  bool _showCompleteForm = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerRequestDetailProvider(widget.requestId));
    final notifier = ref.read(providerRequestDetailProvider(widget.requestId).notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          state.request?['title'] as String? ?? 'Talep Detayı',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: notifier.loadDetail,
            ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProviderRequestDetailState state,
    ProviderRequestDetailNotifier notifier,
  ) {
    if (state.loading && state.request == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2),
      );
    }

    if (state.error != null && state.request == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: notifier.loadDetail,
              child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.blue600)),
            ),
          ],
        ),
      );
    }

    if (state.request == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_outlined, size: 48, color: AppColors.gray300),
            SizedBox(height: 12),
            Text('Talep bulunamadı', style: TextStyle(color: AppColors.gray500, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.blue600,
      onRefresh: notifier.loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequestDetailCard(request: state.request!),
            const SizedBox(height: 12),

            if (state.isInfoRequested) ...[
              _AlertCard(
                icon: Icons.schedule_outlined,
                iconColor: AppColors.amber600,
                bg: AppColors.amber50,
                title: 'Ek Bilgi Bekleniyor',
                description: 'Müşteriye ek bilgi talebi gönderildi, yanıt bekleniyor.',
              ),
              const SizedBox(height: 12),
            ],

            if (state.isInfoProvided && state.additionalInfo != null) ...[
              _AdditionalInfoCard(info: state.additionalInfo!),
              const SizedBox(height: 12),
            ],

            if (state.acceptedBid != null || state.updates.isNotEmpty) ...[
              _JobUpdatesCard(
                updates: state.updates,
                canUpdate: state.canUpdate,
                showForm: _showUpdateForm,
                submitting: state.postingUpdate,
                onShowForm: () => setState(() => _showUpdateForm = true),
                onCancelForm: () => setState(() => _showUpdateForm = false),
                onSubmitUpdate: (data) async {
                  final ok = await notifier.postUpdate(data);
                  if (ok && mounted) setState(() => _showUpdateForm = false);
                },
              ),
              const SizedBox(height: 12),
            ],

            if (state.isPendingReview) ...[
              _AlertCard(
                icon: Icons.star_outline,
                iconColor: AppColors.amber600,
                bg: AppColors.amber50,
                title: 'Değerlendirme Bekleniyor',
                description: 'İşi tamamladınız. Müşteri değerlendirmesini bekliyorsunuz.',
              ),
              const SizedBox(height: 12),
            ],

            if (state.isCompleted) ...[
              _AlertCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.primary600,
                bg: AppColors.green50,
                title: 'Talep Tamamlandı',
                description: 'Müşteri değerlendirmesini yaptı. Bu talep başarıyla tamamlandı.',
              ),
              const SizedBox(height: 12),
            ],

            if (state.actionError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.red700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.actionError!, style: const TextStyle(fontSize: 13, color: AppColors.red700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (state.canBid && !_showBidForm && !_showInfoRequestForm) ...[
              _ActionButtons(
                canRequestInfo: state.canRequestInfo,
                dismissing: state.dismissing,
                onDismiss: () => _showDismissDialog(context, notifier),
                onRequestInfo: () => setState(() => _showInfoRequestForm = true),
                onBid: () => setState(() => _showBidForm = true),
              ),
              const SizedBox(height: 12),
            ],

            if (_showInfoRequestForm) ...[
              _InfoRequestForm(
                submitting: state.requestingInfo,
                onSubmit: (data) async {
                  final ok = await notifier.requestInfo(data);
                  if (ok && mounted) setState(() => _showInfoRequestForm = false);
                },
                onCancel: () => setState(() => _showInfoRequestForm = false),
              ),
              const SizedBox(height: 12),
            ],

            if (_showBidForm) ...[
              _BidForm(
                submitting: state.submittingBid,
                onSubmit: (price, description, estimatedDuration) async {
                  final ok = await notifier.submitBid(
                    price: price,
                    description: description,
                    estimatedDuration: estimatedDuration,
                  );
                  if (ok && mounted) {
                    setState(() => _showBidForm = false);
                    if (context.mounted) context.go('/provider/bids');
                  }
                },
                onCancel: () => setState(() => _showBidForm = false),
              ),
              const SizedBox(height: 12),
            ],

            if (state.canComplete && !_showUpdateForm && !_showCompleteForm) ...[
              _CompleteJobButton(
                onTap: () => setState(() => _showCompleteForm = true),
              ),
              const SizedBox(height: 12),
            ],

            if (_showCompleteForm) ...[
              _CompleteJobForm(
                submitting: state.completing,
                onSubmit: (data) async {
                  final ok = await notifier.completeJob(
                    workDone: data['workDone'] as String,
                    partsUsed: data['partsUsed'] as String?,
                    laborCost: data['laborCost'] as num?,
                    partsCost: data['partsCost'] as num?,
                    totalCost: data['totalCost'] as num?,
                  );
                  if (ok && mounted) setState(() => _showCompleteForm = false);
                },
                onCancel: () => setState(() => _showCompleteForm = false),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDismissDialog(BuildContext context, ProviderRequestDetailNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.red700),
            SizedBox(width: 8),
            Text('Talebi Reddet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          'Bu talep listenizden kaldırılacak, müşteri bilgilendirilmeyecek.',
          style: TextStyle(fontSize: 14, color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final ok = await notifier.dismissRequest();
              if (ok) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) context.go('/provider/requests');
              }
            },
            child: const Text('Evet, Reddet'),
          ),
        ],
      ),
    );
  }
}

// ─── Request Detail Card ──────────────────────────────────────────────────────

class _RequestDetailCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const _RequestDetailCard({required this.request});

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

  @override
  Widget build(BuildContext context) {
    final title = request['title'] as String? ?? '';
    final description = request['description'] as String? ?? '';
    final status = request['status'] as String? ?? '';
    final brand = request['vehicleBrand'] as String? ?? '';
    final model = request['vehicleModel'] as String? ?? '';
    final year = request['vehicleYear'];
    final plate = request['vehiclePlate'] as String?;
    final fuelType = request['vehicleFuelType'] as String?;
    final transmission = request['vehicleTransmissionType'] as String?;
    final engine = request['vehicleEngineDisplacement'] as String?;
    final customerName = request['customerName'] as String?;
    final customerPhone = request['customerPhone'] as String?;
    final createdAt = request['createdAt'] as String?;
    final urgency = request['urgencyLevel'] as String?;
    final category = request['problemCategory'] as String?;

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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: status),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.6),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Araç', value: '$brand $model${year != null ? ' ($year)' : ''}'.trim()),
                if (plate != null && plate.isNotEmpty) _InfoRow(label: 'Plaka', value: plate),
                if (fuelType != null && fuelType.isNotEmpty) _InfoRow(label: 'Yakıt', value: fuelType),
                if (transmission != null && transmission.isNotEmpty) _InfoRow(label: 'Şanzıman', value: transmission),
                if (engine != null && engine.isNotEmpty) _InfoRow(label: 'Motor', value: '$engine L'),
                if (customerName != null && customerName.isNotEmpty) _InfoRow(label: 'Müşteri', value: customerName),
                if (customerPhone != null && customerPhone.isNotEmpty) _InfoRow(label: 'Telefon', value: customerPhone),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (createdAt != null && createdAt.isNotEmpty)
                _Chip(icon: Icons.calendar_today_outlined, label: _fmtDate(createdAt)),
              if (urgency != null && urgency.isNotEmpty)
                _UrgencyChip(level: urgency),
              if (category != null && category.isNotEmpty)
                _Chip(icon: Icons.category_outlined, label: _categoryLabel(category)),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String key) {
    const labels = {
      'maintenance': 'Periyodik Bakım',
      'engine': 'Motor & Mekanik',
      'electrical': 'Elektrik & Elektronik',
      'body': 'Kaporta & Boya',
      'tire': 'Lastik & Jant',
      'other': 'Diğer',
    };
    return labels[key] ?? key;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.gray700, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  static const _labels = <String, String>{
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

  static const _colors = <String, Color>{
    'open': AppColors.blue600,
    'bidding': Color(0xFF7C3AED),
    'info_requested': AppColors.amber600,
    'info_provided': AppColors.primary600,
    'accepted': AppColors.primary600,
    'in_progress': AppColors.blue600,
    'pending_review': AppColors.amber600,
    'completed': AppColors.gray500,
    'cancelled': AppColors.red700,
  };

  static const _bgColors = <String, Color>{
    'open': Color(0xFFEFF6FF),
    'bidding': Color(0xFFF5F3FF),
    'info_requested': AppColors.amber50,
    'info_provided': AppColors.green50,
    'accepted': AppColors.green50,
    'in_progress': Color(0xFFEFF6FF),
    'pending_review': Color(0xFFFEF3C7),
    'completed': AppColors.gray100,
    'cancelled': AppColors.red50,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;
    final color = _colors[status] ?? AppColors.gray500;
    final bg = _bgColors[status] ?? AppColors.gray100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String level;

  const _UrgencyChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (level) {
      'urgent' => (Icons.priority_high, AppColors.amber600, AppColors.amber50),
      'critical' => (Icons.warning_amber_outlined, AppColors.red700, AppColors.red50),
      _ => (Icons.remove_circle_outline, AppColors.gray500, AppColors.gray100),
    };
    final label = switch (level) {
      'urgent' => 'Acil',
      'critical' => 'Kritik',
      _ => 'Normal',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.gray500),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
        ],
      ),
    );
  }
}

// ─── Additional Info Card ─────────────────────────────────────────────────────

class _AdditionalInfoCard extends StatelessWidget {
  final Map<String, dynamic> info;

  const _AdditionalInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final engine = info['engineDisplacement'] as String?;
    final fuel = info['fuelType'] as String?;
    final transmission = info['transmissionType'] as String?;
    final body = info['bodyType'] as String?;
    final mileage = info['mileage'];
    final notes = info['additionalNotes'] as String?;

    final items = <({IconData icon, String label, String value})>[];
    if (engine != null && engine.isNotEmpty) items.add((icon: Icons.settings_outlined, label: 'Motor Hacmi', value: engine));
    if (fuel != null && fuel.isNotEmpty) items.add((icon: Icons.local_gas_station_outlined, label: 'Yakıt Türü', value: fuel));
    if (transmission != null && transmission.isNotEmpty) items.add((icon: Icons.tune_outlined, label: 'Vites Tipi', value: transmission));
    if (body != null && body.isNotEmpty) items.add((icon: Icons.directions_car_outlined, label: 'Kasa Tipi', value: body));
    if (mileage != null) items.add((icon: Icons.speed_outlined, label: 'Kilometre', value: '${mileage.toString()} km'));

    if (items.isEmpty && (notes == null || notes.isEmpty)) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFFD1FAE5))),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, size: 18, color: AppColors.primary600),
                SizedBox(width: 8),
                Text('Müşteri Ek Bilgileri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF064E3B))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isNotEmpty)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.0,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: items.map((item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 16, color: AppColors.gray400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.label, style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                                Text(item.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                if (notes != null && notes.isNotEmpty) ...[
                  if (items.isNotEmpty) const SizedBox(height: 10),
                  Text('Not: $notes', style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Job Updates Card ─────────────────────────────────────────────────────────

class _JobUpdatesCard extends StatelessWidget {
  final List<Map<String, dynamic>> updates;
  final bool canUpdate;
  final bool showForm;
  final bool submitting;
  final VoidCallback onShowForm;
  final VoidCallback onCancelForm;
  final Future<void> Function(Map<String, dynamic>) onSubmitUpdate;

  const _JobUpdatesCard({
    required this.updates,
    required this.canUpdate,
    required this.showForm,
    required this.submitting,
    required this.onShowForm,
    required this.onCancelForm,
    required this.onSubmitUpdate,
  });

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

  String _typeLabel(String type) => switch (type) {
    'progress' => 'İlerleme',
    'delay' => 'Gecikme',
    'completed' => 'Tamamlandı',
    _ => type,
  };

  Color _typeColor(String type) => switch (type) {
    'progress' => AppColors.blue600,
    'delay' => AppColors.amber600,
    'completed' => AppColors.primary600,
    _ => AppColors.gray500,
  };

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
                const Icon(Icons.list_alt_outlined, size: 18, color: AppColors.blue600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('İş Günlüğü', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.gray900)),
                ),
                if (canUpdate && !showForm)
                  TextButton.icon(
                    onPressed: onShowForm,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Güncelleme Ekle', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.blue600),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (showForm) ...[
                  _JobUpdateForm(
                    submitting: submitting,
                    onSubmit: onSubmitUpdate,
                    onCancel: onCancelForm,
                  ),
                  if (updates.isNotEmpty) const SizedBox(height: 16),
                ],
                if (updates.isEmpty && !showForm)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Henüz güncelleme eklenmedi.', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                    ),
                  ),
                ...updates.asMap().entries.map((entry) {
                  final i = entry.key;
                  final update = entry.value;
                  final type = update['updateType'] as String? ?? '';
                  final desc = update['description'] as String? ?? '';
                  final date = update['createdAt'] as String?;
                  final color = _typeColor(type);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              type == 'completed' ? Icons.check : type == 'delay' ? Icons.warning_amber_outlined : Icons.update_outlined,
                              size: 14,
                              color: color,
                            ),
                          ),
                          if (i < updates.length - 1)
                            Container(width: 2, height: 32, color: AppColors.gray200),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: i < updates.length - 1 ? 12 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(_typeLabel(type), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                                  ),
                                  const Spacer(),
                                  if (date != null)
                                    Text(_fmtDate(date), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String description;

  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: iconColor)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 13, color: iconColor.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool canRequestInfo;
  final bool dismissing;
  final VoidCallback onDismiss;
  final VoidCallback onRequestInfo;
  final VoidCallback onBid;

  const _ActionButtons({
    required this.canRequestInfo,
    required this.dismissing,
    required this.onDismiss,
    required this.onRequestInfo,
    required this.onBid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: dismissing ? null : onDismiss,
          icon: dismissing
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red700))
              : const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Reddet'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red700,
            side: const BorderSide(color: AppColors.red700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const Spacer(),
        if (canRequestInfo) ...[
          OutlinedButton.icon(
            onPressed: onRequestInfo,
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Ek Bilgi İste'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gray700,
              side: const BorderSide(color: AppColors.gray300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton.icon(
          onPressed: onBid,
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('Teklif Ver'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ─── Bid Form ─────────────────────────────────────────────────────────────────

class _BidForm extends StatefulWidget {
  final bool submitting;
  final Future<void> Function(num price, String? description, String? estimatedDuration) onSubmit;
  final VoidCallback onCancel;

  const _BidForm({required this.submitting, required this.onSubmit, required this.onCancel});

  @override
  State<_BidForm> createState() => _BidFormState();
}

class _BidFormState extends State<_BidForm> {
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue600.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.send_outlined, size: 18, color: AppColors.blue600),
                SizedBox(width: 8),
                Text('Teklif Ver', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.gray900)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('Fiyat (₺)', hint: 'Örn: 1500'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Fiyat zorunlu';
                if (num.tryParse(v.trim()) == null) return 'Geçerli bir sayı girin';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: _inputDecoration('Tahmini Süre', hint: 'Örn: 2-3 iş günü'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: _inputDecoration('Açıklama', hint: 'Müşteriye iletmek istediğiniz bilgiler...'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.submitting ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: const BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.submitting
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSubmit(
                                num.parse(_priceController.text.trim()),
                                _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                                _durationController.text.trim().isEmpty ? null : _durationController.text.trim(),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: widget.submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Teklif Gönder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    labelStyle: const TextStyle(fontSize: 14, color: AppColors.gray500),
  );
}

// ─── Info Request Form ────────────────────────────────────────────────────────

class _InfoRequestForm extends StatefulWidget {
  final bool submitting;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const _InfoRequestForm({required this.submitting, required this.onSubmit, required this.onCancel});

  @override
  State<_InfoRequestForm> createState() => _InfoRequestFormState();
}

class _InfoRequestFormState extends State<_InfoRequestForm> {
  bool _engineDisplacement = false;
  bool _fuelType = false;
  bool _transmissionType = false;
  bool _bodyType = false;
  bool _mileage = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anySelected = _engineDisplacement || _fuelType || _transmissionType || _bodyType || _mileage;

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
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.gray700),
              SizedBox(width: 8),
              Text('Ek Bilgi İste', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Müşteriden istediğiniz bilgileri seçin:', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 12),
          _CheckItem(label: 'Motor Hacmi', value: _engineDisplacement, onChanged: (v) => setState(() => _engineDisplacement = v!)),
          _CheckItem(label: 'Yakıt Türü', value: _fuelType, onChanged: (v) => setState(() => _fuelType = v!)),
          _CheckItem(label: 'Vites Tipi', value: _transmissionType, onChanged: (v) => setState(() => _transmissionType = v!)),
          _CheckItem(label: 'Kasa Tipi', value: _bodyType, onChanged: (v) => setState(() => _bodyType = v!)),
          _CheckItem(label: 'Kilometre', value: _mileage, onChanged: (v) => setState(() => _mileage = v!)),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Ek Not (isteğe bağlı)',
              hintText: 'Müşteriye özel not ekleyin...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              labelStyle: const TextStyle(fontSize: 14, color: AppColors.gray500),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.submitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.submitting || !anySelected
                      ? null
                      : () {
                          widget.onSubmit({
                            'engineDisplacement': _engineDisplacement,
                            'fuelType': _fuelType,
                            'transmissionType': _transmissionType,
                            'bodyType': _bodyType,
                            'mileage': _mileage,
                            if (_notesController.text.trim().isNotEmpty)
                              'additionalNotes': _notesController.text.trim(),
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: widget.submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gönder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckItem({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray700)),
      activeColor: AppColors.blue600,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ─── Job Update Form ──────────────────────────────────────────────────────────

class _JobUpdateForm extends StatefulWidget {
  final bool submitting;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const _JobUpdateForm({required this.submitting, required this.onSubmit, required this.onCancel});

  @override
  State<_JobUpdateForm> createState() => _JobUpdateFormState();
}

class _JobUpdateFormState extends State<_JobUpdateForm> {
  String _updateType = 'progress';
  final _descController = TextEditingController();
  final _delayReasonController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    _delayReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Güncelleme Ekle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'progress', label: Text('İlerleme'), icon: Icon(Icons.update_outlined, size: 16)),
              ButtonSegment(value: 'delay', label: Text('Gecikme'), icon: Icon(Icons.warning_amber_outlined, size: 16)),
              ButtonSegment(value: 'completed', label: Text('Tamamlandı'), icon: Icon(Icons.check_circle_outline, size: 16)),
            ],
            selected: {_updateType},
            onSelectionChanged: (v) => setState(() => _updateType = v.first),
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Açıklama *',
              hintText: 'Yapılan işlem veya durum hakkında bilgi verin...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              labelStyle: const TextStyle(fontSize: 14, color: AppColors.gray500),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_updateType == 'delay') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _delayReasonController,
              decoration: InputDecoration(
                labelText: 'Gecikme Nedeni',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                labelStyle: const TextStyle(fontSize: 14, color: AppColors.gray500),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.submitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.submitting
                      ? null
                      : () {
                          final desc = _descController.text.trim();
                          if (desc.isEmpty) return;
                          final data = <String, dynamic>{
                            'updateType': _updateType,
                            'description': desc,
                            if (_updateType == 'delay' && _delayReasonController.text.trim().isNotEmpty)
                              'delayReason': _delayReasonController.text.trim(),
                          };
                          widget.onSubmit(data);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: widget.submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gönder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Complete Job Button ──────────────────────────────────────────────────────

class _CompleteJobButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CompleteJobButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('İşi Tamamla', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Complete Job Form ────────────────────────────────────────────────────────

class _CompleteJobForm extends StatefulWidget {
  final bool submitting;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
  final VoidCallback onCancel;

  const _CompleteJobForm({
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_CompleteJobForm> createState() => _CompleteJobFormState();
}

class _CompleteJobFormState extends State<_CompleteJobForm> {
  final _workDoneCtrl = TextEditingController();
  final _partsUsedCtrl = TextEditingController();
  final _laborCostCtrl = TextEditingController();
  final _partsCostCtrl = TextEditingController();
  final _totalCostCtrl = TextEditingController();

  @override
  void dispose() {
    _workDoneCtrl.dispose();
    _partsUsedCtrl.dispose();
    _laborCostCtrl.dispose();
    _partsCostCtrl.dispose();
    _totalCostCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary600, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.primary600, size: 18),
              SizedBox(width: 8),
              Text('İşi Tamamla', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _workDoneCtrl,
            maxLines: 3,
            decoration: _fieldDecoration('Yapılan İşler *', 'Örn: Ön fren balataları değiştirildi, disk kontrol edildi...'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _partsUsedCtrl,
            decoration: _fieldDecoration('Kullanılan Parçalar', 'Örn: Bosch balata seti, 2 adet'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _laborCostCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('İşçilik (₺)', 'Örn: 300'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _partsCostCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('Parça (₺)', 'Örn: 750'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _totalCostCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration('Toplam (₺)', 'Örn: 1050'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.submitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.submitting
                      ? null
                      : () {
                          final workDone = _workDoneCtrl.text.trim();
                          if (workDone.isEmpty) return;
                          widget.onSubmit({
                            'workDone': workDone,
                            'partsUsed': _partsUsedCtrl.text.trim().isEmpty ? null : _partsUsedCtrl.text.trim(),
                            'laborCost': num.tryParse(_laborCostCtrl.text.trim()),
                            'partsCost': num.tryParse(_partsCostCtrl.text.trim()),
                            'totalCost': num.tryParse(_totalCostCtrl.text.trim()),
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: widget.submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tamamla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary600)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    labelStyle: const TextStyle(fontSize: 13, color: AppColors.gray500),
    hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
    filled: true,
    fillColor: Colors.white,
  );
}
