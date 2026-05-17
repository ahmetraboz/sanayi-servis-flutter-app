import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';

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

// ─── Urgency config ───────────────────────────────────────────────────────────

typedef _Urg = ({String label, Color bg, Color text});

const _urgency = <String, _Urg>{
  'low':    (label: 'Acele Değil', bg: Color(0xFFDCFCE7), text: Color(0xFF16A34A)),
  'normal': (label: 'Normal',      bg: Color(0xFFFEF9C3), text: Color(0xFFCA8A04)),
  'urgent': (label: 'Acil',        bg: Color(0xFFFEE2E2), text: Color(0xFFDC2626)),
};

// ─── Card ─────────────────────────────────────────────────────────────────────

class ProviderRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const ProviderRequestCard({super.key, required this.request});

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const kMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${kMonths[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = request['title'] as String? ?? 'Başlıksız Talep';
    final description = request['description'] as String? ?? '';
    final brand = request['vehicleBrand'] as String? ?? '';
    final model = request['vehicleModel'] as String? ?? '';
    final year = request['vehicleYear'] as int?;
    final customerName = request['customerName'] as String? ?? 'Müşteri';
    final createdAt = request['createdAt'] as String? ?? '';
    final category = request['problemCategory'] as String?;
    final urgency = request['urgencyLevel'] as String?;

    final cat = category != null ? _categories[category] : null;
    final urg = urgency != null ? _urgency[urgency] : null;

    return GestureDetector(
      onTap: () => context.push('/provider/requests/${request['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cat != null || urg != null) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (cat != null)
                    _Badge(label: cat.label, bg: cat.bg, text: cat.text, icon: cat.icon),
                  if (urg != null)
                    _Badge(label: urg.label, bg: urg.bg, text: urg.text),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.gray400),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaItem(
                  icon: Icons.directions_car_outlined,
                  text: '$brand $model${year != null ? ' ($year)' : ''}'.trim(),
                ),
                _MetaItem(icon: Icons.person_outline, text: customerName),
                if (createdAt.isNotEmpty)
                  _MetaItem(icon: Icons.calendar_today_outlined, text: _formatDate(createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  final IconData? icon;

  const _Badge({required this.label, required this.bg, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
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

// ─── Meta item ────────────────────────────────────────────────────────────────

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
