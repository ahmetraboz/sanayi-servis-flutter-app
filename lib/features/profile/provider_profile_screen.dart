import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import 'provider_profile_notifier.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  bool _editing = false;

  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _taxNumberCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _descriptionCtrl;

  @override
  void initState() {
    super.initState();
    _companyNameCtrl = TextEditingController();
    _taxNumberCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _taxNumberCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> profile) {
    _companyNameCtrl.text = profile['companyName'] as String? ?? '';
    _taxNumberCtrl.text = profile['taxNumber'] as String? ?? '';
    _addressCtrl.text = profile['address'] as String? ?? '';
    _cityCtrl.text = profile['city'] as String? ?? '';
    _districtCtrl.text = profile['district'] as String? ?? '';
    _descriptionCtrl.text = profile['description'] as String? ?? '';
  }

  void _startEditing(Map<String, dynamic> profile) {
    _populateControllers(profile);
    setState(() => _editing = true);
  }

  void _cancelEditing(Map<String, dynamic> profile) {
    _populateControllers(profile);
    setState(() => _editing = false);
  }

  Future<void> _saveProfile() async {
    final notifier = ref.read(providerProfileProvider.notifier);
    final ok = await notifier.saveProfile({
      'companyName': _companyNameCtrl.text.trim(),
      'taxNumber': _taxNumberCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
    });
    if (ok && mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşletme profiliniz güncellendi'),
          backgroundColor: AppColors.blue600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: 'İşletme Profili',
              action: GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.red50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, size: 16, color: AppColors.red700),
                      SizedBox(width: 5),
                      Text('Çıkış', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red700)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProviderProfileState state) {
    if (state.loading && state.profile == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2));
    }

    if (state.error != null && state.profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: ref.read(providerProfileProvider.notifier).loadProfile,
              child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.blue600)),
            ),
          ],
        ),
      );
    }

    final profile = state.profile!;

    return RefreshIndicator(
      color: AppColors.blue600,
      onRefresh: ref.read(providerProfileProvider.notifier).loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompanyBanner(profile: profile, onEditTap: () => _startEditing(profile)),
            const SizedBox(height: 16),
            _ApprovalBanner(status: state.approvalStatus ?? 'pending'),
            const SizedBox(height: 16),

            if (state.saveError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.red100)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.red700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.saveError!, style: const TextStyle(fontSize: 13, color: AppColors.red700))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_editing)
              _EditForm(
                companyNameCtrl: _companyNameCtrl,
                taxNumberCtrl: _taxNumberCtrl,
                addressCtrl: _addressCtrl,
                cityCtrl: _cityCtrl,
                districtCtrl: _districtCtrl,
                descriptionCtrl: _descriptionCtrl,
                saving: state.saving,
                onSave: _saveProfile,
                onCancel: () => _cancelEditing(profile),
              )
            else
              _InfoView(profile: profile),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

// ─── Company Banner ───────────────────────────────────────────────────────────

class _CompanyBanner extends ConsumerWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEditTap;

  const _CompanyBanner({required this.profile, required this.onEditTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = profile['companyName'] as String? ?? 'İşletme';
    final city = profile['city'] as String?;
    final logoUrl = profile['logoUrl'] as String?;
    final googlePlaceId = profile['googlePlaceId'] as String?;

    final baseUrl = ref.read(apiClientProvider).baseUrl.replaceAll(RegExp(r'/$'), '');
    final photoUrl = logoUrl != null && logoUrl.isNotEmpty
        ? logoUrl
        : googlePlaceId != null
            ? '$baseUrl/api/public/place-photo?placeId=$googlePlaceId'
            : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, _e) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, _e) => const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue600),
                          ),
                        )
                      : const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue600),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                      if (city != null && city.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.gray400),
                            const SizedBox(width: 3),
                            Text(city, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onEditTap,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Düzenle', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue600,
                    side: const BorderSide(color: AppColors.blue600),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// ─── Approval Banner ──────────────────────────────────────────────────────────

class _ApprovalBanner extends StatelessWidget {
  final String status;

  const _ApprovalBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg, label, desc) = switch (status) {
      'approved' => (
        Icons.shield_outlined,
        AppColors.primary600,
        AppColors.green50,
        'Hesabınız Doğrulandı',
        'İşletme profiliniz admin tarafından onaylandı.',
      ),
      'rejected' => (
        Icons.cancel_outlined,
        AppColors.red700,
        AppColors.red50,
        'Hesabınız Reddedildi',
        'Profiliniz reddedildi. Lütfen bilgilerinizi kontrol edin.',
      ),
      _ => (
        Icons.schedule_outlined,
        AppColors.amber600,
        AppColors.amber50,
        'Onay Bekleniyor',
        'İşletme profiliniz admin onayı bekliyor.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info View (read-only) ────────────────────────────────────────────────────

class _InfoView extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _InfoView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('Firma Adı', profile['companyName'] as String?),
      ('Vergi Numarası', profile['taxNumber'] as String?),
      ('Adres', profile['address'] as String?),
      ('İl', profile['city'] as String?),
      ('İlçe', profile['district'] as String?),
      ('Açıklama', profile['description'] as String?),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, size: 16, color: AppColors.blue600),
                SizedBox(width: 8),
                Text('İşletme Bilgileri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: fields.map((field) {
                final (label, value) = field;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text(
                          (value != null && value.isNotEmpty) ? value : '—',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: (value != null && value.isNotEmpty) ? AppColors.gray900 : AppColors.gray300,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Form ────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  final TextEditingController companyNameCtrl;
  final TextEditingController taxNumberCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController descriptionCtrl;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditForm({
    required this.companyNameCtrl,
    required this.taxNumberCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.districtCtrl,
    required this.descriptionCtrl,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue600.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: AppColors.blue600),
              SizedBox(width: 8),
              Text('Bilgileri Düzenle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 16),
          _Field(label: 'Firma Adı *', ctrl: companyNameCtrl, icon: Icons.storefront_outlined),
          const SizedBox(height: 12),
          _Field(label: 'Vergi Numarası', ctrl: taxNumberCtrl, icon: Icons.badge_outlined, keyboard: TextInputType.number),
          const SizedBox(height: 12),
          _Field(label: 'Adres', ctrl: addressCtrl, icon: Icons.location_on_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Field(label: 'İl', ctrl: cityCtrl, icon: Icons.map_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _Field(label: 'İlçe', ctrl: districtCtrl, icon: Icons.map_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          _Field(label: 'İşletme Açıklaması', ctrl: descriptionCtrl, icon: Icons.description_outlined, maxLines: 4),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('İptal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType? keyboard;
  final int maxLines;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.keyboard,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
