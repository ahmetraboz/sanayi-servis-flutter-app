import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/provider_api_service.dart';
import '../../../core/theme/theme.dart';
import 'provider_guest_booking_detail_notifier.dart';

class ProviderGuestBookingDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const ProviderGuestBookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ProviderGuestBookingDetailScreen> createState() => _ProviderGuestBookingDetailScreenState();
}

class _ProviderGuestBookingDetailScreenState extends ConsumerState<ProviderGuestBookingDetailScreen> {
  bool _showQuoteForm = false;
  bool _showUpdateForm = false;
  bool _showRejectConfirm = false;
  bool _editingQuote = false;

  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _updateDescController = TextEditingController();
  final _partsController = TextEditingController();
  String _updateType = 'progress';

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

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    _updateDescController.dispose();
    _partsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerGuestBookingDetailProvider(widget.bookingId));
    final notifier = ref.read(providerGuestBookingDetailProvider(widget.bookingId).notifier);
    final kdvRate = ref.watch(kdvRateProvider).valueOrNull ?? 20.0;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          state.booking?['referenceCode'] != null ? '#${state.booking!['referenceCode']}' : 'Misafir Rezervasyonu',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: notifier.loadDetail,
            ),
        ],
      ),
      body: _buildBody(context, state, notifier, kdvRate),
    );
  }

  Widget _buildBody(BuildContext context, ProviderGuestBookingDetailState state, ProviderGuestBookingDetailNotifier notifier, double kdvRate) {
    if (state.loading && state.booking == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2));
    }

    if (state.error != null && state.booking == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: notifier.loadDetail, child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.blue600))),
          ],
        ),
      );
    }

    if (state.booking == null) return const SizedBox.shrink();

    return RefreshIndicator(
      color: AppColors.blue600,
      onRefresh: notifier.loadDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressStepper(state: state),
          const SizedBox(height: 16),
          if (state.actionError != null) ...[
            _AlertCard(message: state.actionError!, isError: true),
            const SizedBox(height: 12),
          ],
          _StatusAlerts(state: state),
          _BookingInfoCard(booking: state.booking!, fmtDate: _fmtDate),
          const SizedBox(height: 12),
          _DamageReportsSection(booking: state.booking!),
          const SizedBox(height: 12),
          _ResponseSection(
            state: state,
            notifier: notifier,
            showQuoteForm: _showQuoteForm,
            editingQuote: _editingQuote,
            showRejectConfirm: _showRejectConfirm,
            priceController: _priceController,
            noteController: _noteController,
            onToggleQuote: (v) => setState(() {
              _showQuoteForm = v;
              _editingQuote = state.isQuoted;
              if (v && state.isQuoted) {
                _priceController.text = (state.myResponse?['price'] ?? '').toString();
                _noteController.text = (state.myResponse?['note'] ?? '').toString();
              }
            }),
            onToggleReject: (v) => setState(() => _showRejectConfirm = v),
            onSubmitQuote: () async {
              final price = double.tryParse(_priceController.text.trim());
              if (price == null || price <= 0) return;
              final ok = await notifier.submitQuote(price: price, note: _noteController.text.trim());
              if (ok && mounted) {
                setState(() {
                  _showQuoteForm = false;
                  _editingQuote = false;
                  _priceController.clear();
                  _noteController.clear();
                });
              }
            },
            onReject: () async {
              final ok = await notifier.rejectBooking(note: _noteController.text.trim());
              if (ok && mounted) setState(() => _showRejectConfirm = false);
            },
          ),
          if (state.canAddUpdate) ...[
            const SizedBox(height: 12),
            if (state.status == 'accepted')
              _MarkInProgressButton(state: state, onPressed: () => notifier.markInProgress()),
            const SizedBox(height: 12),
            _UpdateFormSection(
              state: state,
              showForm: _showUpdateForm,
              updateType: _updateType,
              descController: _updateDescController,
              partsController: _partsController,
              initialKdvRate: kdvRate,
              agreedPrice: state.myResponse?['price'],
              onToggle: (v) => setState(() => _showUpdateForm = v),
              onTypeChanged: (t) => setState(() => _updateType = t),
              onSubmit: (costItems, kdvRateVal, kdvAmount, overBudgetReason) async {
                final desc = _updateDescController.text.trim();
                if (desc.isEmpty) return false;
                return await notifier.postUpdate(
                  updateType: _updateType,
                  description: desc,
                  partsUsed: _partsController.text.trim().isNotEmpty ? _partsController.text.trim() : null,
                  costItems: costItems,
                  kdvRate: kdvRateVal,
                  kdvAmount: kdvAmount,
                  overBudgetReason: overBudgetReason,
                );
              },
              onSuccess: () {
                if (mounted) {
                  setState(() {
                    _showUpdateForm = false;
                    _updateDescController.clear();
                    _partsController.clear();
                    _updateType = 'progress';
                  });
                }
              },
            ),
          ],
          if (state.updates.isNotEmpty) ...[
            const SizedBox(height: 12),
            _JobUpdatesCard(updates: state.updates, fmtDate: _fmtDate),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Progress Stepper ─────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final ProviderGuestBookingDetailState state;

  const _ProgressStepper({required this.state});

  static const _steps = [
    ('pending', 'Talep Alındı'),
    ('quoted', 'Fiyat Verildi'),
    ('accepted', 'Kabul Edildi'),
    ('in_progress', 'İşlemde'),
    ('completed', 'Tamamlandı'),
  ];

  int get _currentStep {
    final status = state.status ?? 'pending';
    final rStatus = state.responseStatus ?? '';
    if (status == 'completed' || status == 'pending_review') return 4;
    if (status == 'in_progress') return 3;
    if (status == 'accepted') return 2;
    if (rStatus == 'quoted') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentStep;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final done = stepIndex < current;
            return Expanded(
              child: Container(height: 2, color: done ? AppColors.blue600 : AppColors.gray200),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < current;
          final active = stepIndex == current;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.blue600 : (active ? AppColors.blue600.withValues(alpha: 0.15) : AppColors.gray100),
                  shape: BoxShape.circle,
                  border: active ? Border.all(color: AppColors.blue600, width: 2) : null,
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Center(child: Text('${stepIndex + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? AppColors.blue600 : AppColors.gray400))),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[stepIndex].$2,
                style: TextStyle(fontSize: 9, color: (done || active) ? AppColors.blue600 : AppColors.gray400, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Status Alerts ────────────────────────────────────────────────────────────

class _StatusAlerts extends StatelessWidget {
  final ProviderGuestBookingDetailState state;

  const _StatusAlerts({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isCompleted) {
      return Column(children: [
        _AlertCard(message: 'Bu rezervasyon tamamlanmıştır.', isError: false),
        const SizedBox(height: 12),
      ]);
    }
    if (state.isPendingReview) {
      return Column(children: [
        _AlertCard(message: 'İş tamamlandı, müşteri değerlendirmesi bekleniyor.', isError: false, color: AppColors.amber600, bgColor: const Color(0xFFFEF9C3)),
        const SizedBox(height: 12),
      ]);
    }
    if (state.guestAccepted && state.status == 'accepted') {
      return Column(children: [
        _AlertCard(message: 'Misafir teklifinizi kabul etti! İşi başlatabilirsiniz.', isError: false),
        const SizedBox(height: 12),
      ]);
    }
    return const SizedBox.shrink();
  }
}

class _AlertCard extends StatelessWidget {
  final String message;
  final bool isError;
  final Color? color;
  final Color? bgColor;

  const _AlertCard({required this.message, required this.isError, this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isError ? AppColors.red700 : AppColors.primary600);
    final bg = bgColor ?? (isError ? AppColors.red50 : AppColors.green50);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.info_outline, size: 18, color: c),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ─── Booking Info ─────────────────────────────────────────────────────────────

class _BookingInfoCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String Function(String?) fmtDate;

  const _BookingInfoCard({required this.booking, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    final name = booking['name'] as String? ?? '';
    final phone = booking['phone'] as String? ?? '';
    final city = booking['city'] as String? ?? '';
    final preferredDate = booking['preferredDate'] as String?;
    final title = booking['title'] as String? ?? '';
    final description = booking['description'] as String?;
    final brand = booking['brand'] as String? ?? '';
    final model = booking['model'] as String? ?? '';
    final year = booking['year'];
    final plate = booking['licensePlate'] as String?;
    final fuel = booking['fuelType'] as String?;
    final transmission = booking['transmissionType'] as String?;
    final mileage = booking['mileage'];
    final color = booking['color'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4)),
          ],
          const Divider(height: 20, color: AppColors.gray100),
          const Text('İletişim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.person_outline, label: name),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.phone_outlined, label: phone),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.location_on_outlined, label: city),
          if (preferredDate != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'Tercih: ${fmtDate(preferredDate)}'),
          ],
          const Divider(height: 20, color: AppColors.gray100),
          const Text('Araç', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (brand.isNotEmpty || model.isNotEmpty) _VehicleChip(label: '$brand $model${year != null ? ' ($year)' : ''}'.trim()),
              if (plate != null && plate.isNotEmpty) _VehicleChip(label: plate),
              if (fuel != null && fuel.isNotEmpty) _VehicleChip(label: fuel),
              if (transmission != null && transmission.isNotEmpty) _VehicleChip(label: transmission),
              if (mileage != null) _VehicleChip(label: '$mileage km'),
              if (color != null && color.isNotEmpty) _VehicleChip(label: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
      ],
    );
  }
}

class _VehicleChip extends StatelessWidget {
  final String label;

  const _VehicleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.gray200)),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray700, fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Damage Reports ───────────────────────────────────────────────────────────

class _DamageReportsSection extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _DamageReportsSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final raw = booking['damageReports'];
    if (raw == null) return const SizedBox.shrink();

    List<Map<String, dynamic>> reports = [];
    if (raw is List) {
      reports = raw.whereType<Map<String, dynamic>>().toList();
    }
    if (reports.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDE68A))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_fix_high_outlined, size: 16, color: AppColors.amber600),
              SizedBox(width: 6),
              Text('Yapay Zeka Hasar Tespiti', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.amber600)),
            ],
          ),
          const SizedBox(height: 12),
          ...reports.map((report) {
            final part = report['part'] as String? ?? '';
            final severity = report['severity'] as String? ?? '';
            final desc = report['description'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(part, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                      const SizedBox(width: 8),
                      _SeverityBadge(severity: severity),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (severity) {
      'high' || 'critical' => ('Yüksek', AppColors.red700, AppColors.red50),
      'medium' => ('Orta', AppColors.amber600, const Color(0xFFFEF9C3)),
      _ => ('Düşük', AppColors.primary600, AppColors.green50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── Response Section ─────────────────────────────────────────────────────────

class _ResponseSection extends StatelessWidget {
  final ProviderGuestBookingDetailState state;
  final ProviderGuestBookingDetailNotifier notifier;
  final bool showQuoteForm;
  final bool editingQuote;
  final bool showRejectConfirm;
  final TextEditingController priceController;
  final TextEditingController noteController;
  final void Function(bool) onToggleQuote;
  final void Function(bool) onToggleReject;
  final VoidCallback onSubmitQuote;
  final VoidCallback onReject;

  const _ResponseSection({
    required this.state,
    required this.notifier,
    required this.showQuoteForm,
    required this.editingQuote,
    required this.showRejectConfirm,
    required this.priceController,
    required this.noteController,
    required this.onToggleQuote,
    required this.onToggleReject,
    required this.onSubmitQuote,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isCompleted || state.isPendingReview) return const SizedBox.shrink();

    if (state.isRejected) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.red100)),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: AppColors.red700),
            SizedBox(width: 8),
            Text('Bu rezervasyonu reddettiniz.', style: TextStyle(fontSize: 13, color: AppColors.red700, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (state.guestAccepted) return const SizedBox.shrink();

    if (state.isQuoted && !showQuoteForm) {
      final price = state.myResponse?['price'];
      final note = state.myResponse?['note'] as String?;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blue600.withValues(alpha: 0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 16, color: AppColors.blue600),
                SizedBox(width: 6),
                Text('Verilen Fiyat Teklifi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue600)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${_fmtPrice(price)} ₺', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray900)),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(note, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => onToggleQuote(true),
              child: const Text('Teklifi Düzenle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(state.isQuoted ? 'Teklifi Düzenle' : 'Rezervasyona Yanıt Ver', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(height: 12),
          if (showQuoteForm || !state.hasResponse) ...[
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDec('Fiyat (₺)', Icons.attach_money),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: _inputDec('Not (opsiyonel)', Icons.notes_outlined),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.submitting ? null : onSubmitQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: state.submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(editingQuote ? 'Teklifi Güncelle' : 'Fiyat Teklifi Ver', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (showQuoteForm) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => onToggleQuote(false), child: const Text('İptal', style: TextStyle(color: AppColors.gray500))),
                ],
              ],
            ),
          ],
          if (!showQuoteForm && !state.hasResponse) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.gray100),
            const SizedBox(height: 8),
            if (!showRejectConfirm)
              GestureDetector(
                onTap: () => onToggleReject(true),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined, size: 16, color: AppColors.red700),
                    SizedBox(width: 6),
                    Text('Reddet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red700)),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reddetmek istediğinizden emin misiniz?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: state.submitting ? null : onReject,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.red700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Reddet'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => onToggleReject(false), child: const Text('İptal', style: TextStyle(color: AppColors.gray500))),
                    ],
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
        contentPadding: const EdgeInsets.all(12),
      );

  static String _fmtPrice(dynamic price) {
    if (price == null) return '0';
    final n = (price is num) ? price.toDouble() : double.tryParse(price.toString()) ?? 0.0;
    return n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

// ─── Mark In Progress ─────────────────────────────────────────────────────────

class _MarkInProgressButton extends StatelessWidget {
  final ProviderGuestBookingDetailState state;
  final VoidCallback onPressed;

  const _MarkInProgressButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: state.submitting ? null : onPressed,
      icon: state.submitting
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.play_arrow_outlined, size: 18),
      label: const Text('İşi Başlat', style: TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue600,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Update Form ──────────────────────────────────────────────────────────────

typedef _SubmitUpdateFn = Future<bool> Function(
  List<Map<String, dynamic>> costItems,
  double? kdvRate,
  double? kdvAmount,
  String? overBudgetReason,
);

class _UpdateFormSection extends StatefulWidget {
  final ProviderGuestBookingDetailState state;
  final bool showForm;
  final String updateType;
  final TextEditingController descController;
  final TextEditingController partsController;
  final void Function(bool) onToggle;
  final double initialKdvRate;
  final dynamic agreedPrice;
  final void Function(String) onTypeChanged;
  final _SubmitUpdateFn onSubmit;
  final VoidCallback onSuccess;

  static const _updateTypes = [
    ('progress', 'İlerleme'),
    ('delay', 'Gecikme'),
    ('completed', 'Tamamlandı'),
  ];

  static const _kdvOptions = [0.0, 10.0, 20.0];

  const _UpdateFormSection({
    required this.state,
    required this.showForm,
    required this.updateType,
    required this.descController,
    required this.partsController,
    this.initialKdvRate = 20.0,
    this.agreedPrice,
    required this.onToggle,
    required this.onTypeChanged,
    required this.onSubmit,
    required this.onSuccess,
  });

  @override
  State<_UpdateFormSection> createState() => _UpdateFormSectionState();
}

class _UpdateFormSectionState extends State<_UpdateFormSection> {
  final List<Map<String, dynamic>> _costItems = [];
  late double _kdvRate = widget.initialKdvRate;
  final _itemNameCtrl = TextEditingController();
  final _itemAmountCtrl = TextEditingController();
  final _overBudgetCtrl = TextEditingController();
  bool _submitting = false;

  double get _subtotal => _costItems.fold(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
  double get _kdvAmount => _subtotal * _kdvRate / 100;
  double get _total => _subtotal + _kdvAmount;

  @override
  void didUpdateWidget(_UpdateFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showForm && !oldWidget.showForm) {
      setState(() => _kdvRate = widget.initialKdvRate);
    } else if (!widget.showForm && oldWidget.showForm) {
      setState(() {
        _costItems.clear();
        _kdvRate = widget.initialKdvRate;
        _itemNameCtrl.clear();
        _itemAmountCtrl.clear();
        _overBudgetCtrl.clear();
      });
    }
  }

  bool get _isOverBudget {
    final agreed = double.tryParse(widget.agreedPrice?.toString() ?? '');
    if (agreed == null || _total == 0) return false;
    return _total > agreed;
  }

  bool get _isSubmitEnabled {
    if (widget.descController.text.trim().isEmpty) return false;
    if (_isOverBudget && _overBudgetCtrl.text.trim().isEmpty) return false;
    return true;
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _itemAmountCtrl.dispose();
    _overBudgetCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemNameCtrl.text.trim();
    final amount = double.tryParse(_itemAmountCtrl.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || amount == null || amount <= 0) return;
    setState(() {
      _costItems.add({'name': name, 'amount': amount});
      _itemNameCtrl.clear();
      _itemAmountCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_isSubmitEnabled) return;
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(
      _costItems,
      _kdvRate > 0 ? _kdvRate : null,
      _kdvAmount > 0 ? _kdvAmount : null,
      _overBudgetCtrl.text.trim().isNotEmpty ? _overBudgetCtrl.text.trim() : null,
    );
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        setState(() {
          _costItems.clear();
          _kdvRate = 0;
        });
        widget.onSuccess();
      }
    }
  }

  String _fmt(double val) => val.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
    filled: true,
    fillColor: AppColors.gray50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
    contentPadding: const EdgeInsets.all(12),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.showForm) {
      return ElevatedButton.icon(
        onPressed: () => widget.onToggle(true),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Güncelleme Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Güncelleme Ekle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _UpdateFormSection._updateTypes.map(((String, String) t) {
              final isSelected = widget.updateType == t.$1;
              return GestureDetector(
                onTap: () => widget.onTypeChanged(t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.blue600 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.blue600 : AppColors.gray200),
                  ),
                  child: Text(t.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.gray600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.descController,
            maxLines: 3,
            decoration: _inputDec('Güncelleme açıklaması...'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.partsController,
            decoration: _inputDec('Kullanılan parçalar (opsiyonel)'),
          ),
          const SizedBox(height: 14),
          const Text('Maliyet Kalemleri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
          const SizedBox(height: 8),
          if (_costItems.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                children: List.generate(_costItems.length, (i) {
                  final item = _costItems[i];
                  final isLast = i == _costItems.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            Expanded(child: Text(item['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
                            Text(
                              '${_fmt((item['amount'] as num?)?.toDouble() ?? 0)} ₺',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _costItems.removeAt(i)),
                              child: const Icon(Icons.close, size: 16, color: AppColors.gray400),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, color: AppColors.gray200),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _itemNameCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDec('Kalem adı'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _itemAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDec('Tutar ₺'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addItem,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_costItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('KDV Oranı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _UpdateFormSection._kdvOptions.map((rate) {
                final active = _kdvRate == rate;
                return GestureDetector(
                  onTap: () => setState(() => _kdvRate = rate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.blue600 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? AppColors.blue600 : AppColors.gray300),
                    ),
                    child: Text('%${rate.toInt()}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.gray600)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                  Text('${_fmt(_total)} ₺', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                ],
              ),
            ),
          ],
          if (_isOverBudget) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 16, color: Color(0xFFEA580C)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toplam tutar kabul edilen teklifin üzerinde. Aşım sebebini belirtin.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFEA580C)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _overBudgetCtrl,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: _inputDec('Bütçe aşım sebebi *'),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (_submitting || widget.state.postingUpdate || !_isSubmitEnabled) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.gray200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: (_submitting || widget.state.postingUpdate)
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gönder', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: () => widget.onToggle(false), child: const Text('İptal', style: TextStyle(color: AppColors.gray500))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Job Updates ──────────────────────────────────────────────────────────────

class _JobUpdatesCard extends StatelessWidget {
  final List<Map<String, dynamic>> updates;
  final String Function(String?) fmtDate;

  const _JobUpdatesCard({required this.updates, required this.fmtDate});

  (String, IconData, Color) _typeStyle(String type) => switch (type) {
    'progress' => ('İlerleme', Icons.trending_up_outlined, AppColors.blue600),
    'delay' => ('Gecikme', Icons.schedule_outlined, AppColors.amber600),
    'completed' => ('Tamamlandı', Icons.check_circle_outline, AppColors.primary600),
    'issue' => ('Sorun', Icons.warning_amber_outlined, AppColors.red700),
    _ => (type, Icons.info_outline, AppColors.gray500),
  };

  String _fmtCost(double val) => val.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İş Günlüğü (${updates.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(height: 12),
          ...updates.reversed.map((u) {
            final typeStr = u['updateType'] as String? ?? '';
            final (typeLabel, typeIcon, typeColor) = _typeStyle(typeStr);
            final desc = u['description'] as String? ?? '';
            final parts = u['partsUsed'] as String?;
            final createdAt = u['createdAt'] as String?;
            final rawCostItems = u['costItems'];
            final costItemsList = rawCostItems is List
                ? rawCostItems.whereType<Map<String, dynamic>>().toList()
                : <Map<String, dynamic>>[];
            final kdvAmount = u['kdvAmount'];
            final kdvRate = u['kdvRate'];
            final costSubtotal = costItemsList.fold<double>(0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
            final costTotal = costSubtotal + ((kdvAmount as num?)?.toDouble() ?? 0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(typeIcon, size: 16, color: typeColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(typeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: typeColor)),
                            const Spacer(),
                            Text(fmtDate(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.4)),
                        if (parts != null && parts.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text('Parçalar: $parts', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                        ],
                        if (costItemsList.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.gray200),
                            ),
                            child: Column(
                              children: [
                                ...costItemsList.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item['name']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                                      Text(
                                        '${_fmtCost((item['amount'] as num?)?.toDouble() ?? 0)} ₺',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray900),
                                      ),
                                    ],
                                  ),
                                )),
                                if (kdvAmount != null) ...[
                                  const Divider(height: 8, color: AppColors.gray200),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('KDV (%${(kdvRate as num?)?.toInt() ?? 0})', style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                      Text('${_fmtCost((kdvAmount as num?)!.toDouble())} ₺', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                    ],
                                  ),
                                ],
                                const Divider(height: 8, color: AppColors.gray200),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Toplam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                                    Text('${_fmtCost(costTotal)} ₺', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
