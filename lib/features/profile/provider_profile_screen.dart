import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/widgets/skeleton.dart';
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
  void _openEditSheet(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileEditSheet(profile: profile),
    );
  }

  void _openPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PasswordChangeSheet(
        onSave: (current, newPwd) => ref.read(providerProfileProvider.notifier).changePassword(current, newPwd),
      ),
    );
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
            const PageHeader(
              title: 'İşletme Profili',
              action: NotificationIconButton(),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProviderProfileState state) {
    if (state.loading && state.profile == null) {
      return const _ProfileSkeleton();
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
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompanyBanner(profile: profile, onEditTap: () => _openEditSheet(context, profile)),
            const SizedBox(height: 16),
            _ApprovalBanner(status: state.approvalStatus ?? 'pending'),
            const SizedBox(height: 16),

            _NavRow(
              icon: Icons.notifications_outlined,
              label: 'Bildirimler',
              color: AppColors.blue600,
              subtitle: 'Tüm bildirimleriniz',
              onTap: () => context.push('/provider/notifications'),
            ),
            const SizedBox(height: 10),
            _NavRow(
              icon: Icons.star_outline_rounded,
              label: 'Puanlamalarım',
              color: const Color(0xFFCA8A04),
              subtitle: state.profile?['averageRating'] != null
                  ? '${state.profile!['averageRating']} ★'
                  : 'Müşteri değerlendirmeleri',
              onTap: () => context.push('/provider/reviews'),
            ),
            const SizedBox(height: 10),
            _NavRow(
              icon: Icons.lock_outline,
              label: 'Şifre Değiştir',
              color: AppColors.gray600,
              subtitle: 'Hesap şifrenizi güncelleyin',
              onTap: () => _openPasswordSheet(context),
            ),

            const SizedBox(height: 16),
            _MapCard(profile: profile),
            const SizedBox(height: 12),
            _PhotosCard(photos: state.photos),
            const SizedBox(height: 12),
            _InfoView(profile: profile),
            const SizedBox(height: 12),
            _ServiceAreasCard(profile: profile),
            const SizedBox(height: 12),
            _WorkingHoursCard(profile: profile),
            const SizedBox(height: 24),
            _LogoutButton(onTap: () => _showLogoutDialog(context)),
            const SizedBox(height: 16),
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

// ─── Photos Card ─────────────────────────────────────────────────────────────

class _PhotosCard extends StatelessWidget {
  final List<String> photos;

  const _PhotosCard({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
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
                Icon(Icons.photo_library_outlined, size: 16, color: AppColors.blue600),
                SizedBox(width: 8),
                Text('İşletme Fotoğrafları', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: photos[i],
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(width: 88, height: 88, color: AppColors.gray100),
                    errorWidget: (context, url, error) => Container(width: 88, height: 88, color: AppColors.gray100, child: const Icon(Icons.broken_image_outlined, color: AppColors.gray300)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _PhotoThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            placeholder: (context, url2) => Container(width: 88, height: 88, color: AppColors.gray100),
            errorWidget: (context, url2, error) => Container(
              width: 88,
              height: 88,
              color: AppColors.gray100,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.gray300),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _confirmRemove(context),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Fotoğrafı Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('Bu fotoğraf silinecek. Emin misiniz?', style: TextStyle(fontSize: 14, color: AppColors.gray600)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('İptal', style: TextStyle(color: AppColors.gray500))),
          ElevatedButton(
            onPressed: () { Navigator.of(dialogContext).pop(); onRemove(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Sil'),
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
                errorWidget: (ctx, url, err) => const SizedBox.shrink(),
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
                            errorWidget: (ctx, url, err) => const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue600),
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

// ─── Profile Skeleton ─────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  static Widget _navRowSkeleton() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Row(
          children: [
            SkeletonBox(height: 36, width: 36, radius: 10),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14, width: 120, radius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(height: 11, width: 180, radius: 4),
                ],
              ),
            ),
            SkeletonBox(height: 16, width: 16, radius: 4),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _CompanyBanner skeleton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Row(
              children: [
                SkeletonBox(height: 72, width: 72, radius: 16),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 18, radius: 5),
                      SizedBox(height: 8),
                      SkeletonBox(height: 13, width: 100, radius: 4),
                      SizedBox(height: 8),
                      SkeletonBox(height: 13, width: 140, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // _ApprovalBanner skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Row(
              children: [
                SkeletonBox(height: 16, width: 16, radius: 8),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 13, radius: 4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Nav rows
          _navRowSkeleton(),
          _navRowSkeleton(),
          const SizedBox(height: 16),
          // _InfoView skeleton
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 14, width: 120, radius: 4),
                const Divider(height: 20),
                ...List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: const Row(
                    children: [
                      SkeletonBox(height: 12, width: 90, radius: 4),
                      SizedBox(width: 16),
                      Expanded(child: SkeletonBox(height: 14, radius: 4)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map Card ────────────────────────────────────────────────────────────────

class _MapCard extends StatefulWidget {
  final Map<String, dynamic> profile;

  const _MapCard({required this.profile});

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  LatLng? _point;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final latStr = widget.profile['latitude'] as String?;
    final lngStr = widget.profile['longitude'] as String?;
    final lat = double.tryParse(latStr ?? '');
    final lng = double.tryParse(lngStr ?? '');

    if (lat != null && lng != null) {
      setState(() => _point = LatLng(lat, lng));
      return;
    }

    final parts = [
      widget.profile['address'] as String?,
      widget.profile['district'] as String?,
      widget.profile['city'] as String?,
      'Türkiye',
    ].whereType<String>().where((s) => s.isNotEmpty).toList();

    if (parts.isEmpty) return;

    setState(() => _loading = true);
    try {
      final query = Uri.encodeComponent(parts.join(', '));
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'SanayiServisApp/1.0');
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      final list = jsonDecode(body) as List<dynamic>;
      if (list.isNotEmpty) {
        final item = list.first as Map<String, dynamic>;
        final resLat = double.tryParse(item['lat'] as String? ?? '');
        final resLng = double.tryParse(item['lon'] as String? ?? '');
        if (resLat != null && resLng != null && mounted) {
          setState(() => _point = LatLng(resLat, resLng));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _point == null) return const SizedBox.shrink();

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
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.blue600),
                SizedBox(width: 8),
                Text('Konum', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
              ],
            ),
          ),
          const Divider(height: 16, indent: 16, endIndent: 16),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 200,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2))
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: _point!,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.bozappz.sanayiServisApp',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _point!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info View ────────────────────────────────────────────────────────────────

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

// ─── Service Areas Card ───────────────────────────────────────────────────────

const _kServiceAreas = [
  (key: 'bakim',    label: 'Periyodik Bakım', icon: Icons.construction_outlined),
  (key: 'motor',    label: 'Motor',       icon: Icons.local_fire_department_outlined),
  (key: 'elektrik', label: 'Elektrik',    icon: Icons.bolt_outlined),
  (key: 'fren',     label: 'Frenler',     icon: Icons.do_not_disturb_on_outlined),
  (key: 'suspan',   label: 'Süspansiyon', icon: Icons.tune_outlined),
  (key: 'kaporta',  label: 'Kaporta',     icon: Icons.brush_outlined),
  (key: 'klima',    label: 'Klima',       icon: Icons.ac_unit_outlined),
  (key: 'lastik',   label: 'Lastik',      icon: Icons.tire_repair_outlined),
  (key: 'vites',    label: 'Şanzıman',    icon: Icons.settings_outlined),
  (key: 'egzoz',    label: 'Egzoz',       icon: Icons.cloud_outlined),
  (key: 'diger',    label: 'Diğer',       icon: Icons.help_outline),
];

class _ServiceAreasCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _ServiceAreasCard({required this.profile});

  List<String> _parseAreas() {
    final raw = profile['serviceAreas'] as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = _parseAreas();

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
                Icon(Icons.build_circle_outlined, size: 16, color: AppColors.blue600),
                SizedBox(width: 8),
                Text('Hizmet Alanları', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: areas.isEmpty
                ? const Text('Henüz hizmet alanı eklenmedi', style: TextStyle(fontSize: 13, color: AppColors.gray400))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: areas.map((key) {
                      final area = _kServiceAreas.where((a) => a.key == key).firstOrNull;
                      if (area == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.info50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(area.icon, size: 14, color: AppColors.blue600),
                            const SizedBox(width: 5),
                            Text(area.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.blue600)),
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

// ─── Working Hours Card ───────────────────────────────────────────────────────

class _WorkingHoursCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  static const _days = [
    ('monday',    'Pazartesi'),
    ('tuesday',   'Salı'),
    ('wednesday', 'Çarşamba'),
    ('thursday',  'Perşembe'),
    ('friday',    'Cuma'),
    ('saturday',  'Cumartesi'),
    ('sunday',    'Pazar'),
  ];

  const _WorkingHoursCard({required this.profile});

  Map<String, dynamic>? _parse() {
    final raw = profile['workingHours'] as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _parse();
    if (hours == null) return const SizedBox.shrink();

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
                Icon(Icons.schedule_outlined, size: 16, color: AppColors.blue600),
                SizedBox(width: 8),
                Text('Çalışma Saatleri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: _days.map((d) {
                final (key, label) = d;
                final day = hours[key] as Map<String, dynamic>?;
                final isOpen = day?['isOpen'] as bool? ?? false;
                final open  = day?['open']  as String? ?? '09:00';
                final close = day?['close'] as String? ?? '18:00';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontWeight: FontWeight.w500)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpen ? AppColors.green50 : AppColors.gray100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOpen ? 'Açık' : 'Kapalı',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? AppColors.primary600 : AppColors.gray400,
                          ),
                        ),
                      ),
                      if (isOpen) ...[
                        const SizedBox(width: 10),
                        Text('$open – $close', style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                      ],
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

// ─── Profile Edit Sheet ───────────────────────────────────────────────────────

class _ProfileEditSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> profile;

  const _ProfileEditSheet({required this.profile});

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _taxNumberCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _descriptionCtrl;
  late List<String> _selectedServiceAreas;
  late Map<String, Map<String, dynamic>> _workingHours;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _companyNameCtrl = TextEditingController(text: p['companyName'] as String? ?? '');
    _taxNumberCtrl   = TextEditingController(text: p['taxNumber']   as String? ?? '');
    _addressCtrl     = TextEditingController(text: p['address']     as String? ?? '');
    _cityCtrl        = TextEditingController(text: p['city']        as String? ?? '');
    _districtCtrl    = TextEditingController(text: p['district']    as String? ?? '');
    _descriptionCtrl = TextEditingController(text: p['description'] as String? ?? '');
    final rawAreas = p['serviceAreas'] as String?;
    _selectedServiceAreas = [];
    if (rawAreas != null && rawAreas.isNotEmpty) {
      try { _selectedServiceAreas = (jsonDecode(rawAreas) as List).cast<String>(); } catch (_) {}
    }
    final raw = p['workingHours'] as String?;
    Map<String, dynamic> parsed = {};
    if (raw != null && raw.isNotEmpty) {
      try { parsed = jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}
    }
    _workingHours = {
      for (final key in ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'])
        key: (parsed[key] as Map<String, dynamic>?) ?? {
          'isOpen': ['monday','tuesday','wednesday','thursday','friday'].contains(key),
          'open': '09:00',
          'close': '18:00',
        }
    };
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

  void _pickTime(String dayKey, String field, String current) {
    final parts = current.split(':');
    var selected = DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(99))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('İptal', style: TextStyle(color: AppColors.gray500)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: const Text('Tamam', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final h = selected.hour.toString().padLeft(2, '0');
                    final m = selected.minute.toString().padLeft(2, '0');
                    setState(() => _workingHours[dayKey] = {
                      ..._workingHours[dayKey]!,
                      field: '$h:$m',
                    });
                  },
                ),
              ],
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: selected,
                minuteInterval: 15,
                onDateTimeChanged: (dt) => selected = dt,
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final ok = await ref.read(providerProfileProvider.notifier).saveProfile({
      'companyName':  _companyNameCtrl.text.trim(),
      'taxNumber':    _taxNumberCtrl.text.trim(),
      'address':      _addressCtrl.text.trim(),
      'city':         _cityCtrl.text.trim(),
      'district':     _districtCtrl.text.trim(),
      'description':  _descriptionCtrl.text.trim(),
      'workingHours': jsonEncode(_workingHours),
      'serviceAreas': jsonEncode(_selectedServiceAreas),
      if (widget.profile['googlePlaceId'] != null) 'googlePlaceId': widget.profile['googlePlaceId'] as String,
      if (widget.profile['latitude'] != null) 'latitude': widget.profile['latitude'] as String,
      if (widget.profile['longitude'] != null) 'longitude': widget.profile['longitude'] as String,
    });
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşletme profiliniz güncellendi'),
          backgroundColor: AppColors.blue600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAndUpload() async {
    final source = await _showSourceSheet(context);
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1920);
    if (picked == null || !mounted) return;
    await ref.read(providerProfileProvider.notifier).uploadPhoto(File(picked.path));
  }

  Future<void> _pickAndUploadLogo() async {
    final source = await _showSourceSheet(context);
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90, maxWidth: 1024);
    if (picked == null || !mounted) return;
    final err = await ref.read(providerProfileProvider.notifier).uploadLogo(File(picked.path));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Logo güncellendi'),
        backgroundColor: err == null ? AppColors.blue600 : AppColors.red700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int? _logoDaysLeft() {
    final updatedAt = ref.read(providerProfileProvider).profile?['logoUpdatedAt'] as String?;
    if (updatedAt == null) return null;
    try {
      final dt = DateTime.parse(updatedAt);
      final daysSince = DateTime.now().difference(dt).inHours / 24;
      const limit = 7;
      if (daysSince >= limit) return null;
      return (limit - daysSince).ceil();
    } catch (_) {
      return null;
    }
  }

  Future<ImageSource?> _showSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Fotoğraf Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900))),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.blue600.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.photo_library_outlined, color: AppColors.blue600)),
              title: const Text('Galeriden Seç', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary600.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary600)),
              title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetState = ref.watch(providerProfileProvider);
    final saving = sheetState.saving;
    final uploading = sheetState.uploadingPhoto;
    final uploadingLogo = sheetState.uploadingLogo;
    final photos = sheetState.photos;
    final logoUrl = sheetState.profile?['logoUrl'] as String?;
    final daysLeft = _logoDaysLeft();
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(99)))),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: AppColors.blue600),
                    SizedBox(width: 8),
                    Text('Profili Düzenle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const Divider(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ─────────────────────────────────────────────
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.gray500),
                      SizedBox(width: 6),
                      Text('İşletme Logosu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: logoUrl != null && logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: CachedNetworkImage(
                                  imageUrl: logoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (ctx, url, err) => const Icon(Icons.storefront_outlined, color: AppColors.blue600),
                                ),
                              )
                            : const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue600),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: (uploadingLogo || daysLeft != null) ? null : _pickAndUploadLogo,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (uploadingLogo || daysLeft != null)
                                      ? AppColors.gray100
                                      : AppColors.blue600.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (uploadingLogo || daysLeft != null)
                                        ? AppColors.gray200
                                        : AppColors.blue600.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (uploadingLogo)
                                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue600))
                                    else
                                      Icon(
                                        logoUrl != null && logoUrl.isNotEmpty ? Icons.refresh : Icons.upload_outlined,
                                        size: 14,
                                        color: daysLeft != null ? AppColors.gray400 : AppColors.blue600,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      logoUrl != null && logoUrl.isNotEmpty ? 'Logoyu Güncelle' : 'Logo Yükle',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: daysLeft != null ? AppColors.gray400 : AppColors.blue600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              daysLeft != null
                                  ? 'Sonraki değişiklik: $daysLeft gün sonra'
                                  : 'JPEG/PNG/WebP/SVG · max 2 MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: daysLeft != null ? AppColors.amber600 : AppColors.gray400,
                                fontWeight: daysLeft != null ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // ── Fotoğraflar ──────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 14, color: AppColors.gray500),
                      const SizedBox(width: 6),
                      const Text('İşletme Fotoğrafları', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: uploading ? null : _pickAndUpload,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.blue600.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: uploading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue600))
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 14, color: AppColors.blue600),
                                    SizedBox(width: 4),
                                    Text('Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (photos.isEmpty)
                    Container(
                      height: 80,
                      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gray200)),
                      child: const Center(child: Text('Henüz fotoğraf eklenmemiş', style: TextStyle(fontSize: 13, color: AppColors.gray400))),
                    )
                  else
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => _PhotoThumb(
                          url: photos[i],
                          onRemove: () => ref.read(providerProfileProvider.notifier).removePhoto(photos[i]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // ── Form alanları ────────────────────────────────────
                  _Field(label: 'Firma Adı *', ctrl: _companyNameCtrl, icon: Icons.storefront_outlined),
                  const SizedBox(height: 12),
                  _Field(label: 'Vergi Numarası', ctrl: _taxNumberCtrl, icon: Icons.badge_outlined, keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  _Field(label: 'Adres', ctrl: _addressCtrl, icon: Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Field(label: 'İl', ctrl: _cityCtrl, icon: Icons.map_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(label: 'İlçe', ctrl: _districtCtrl, icon: Icons.map_outlined)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field(label: 'İşletme Açıklaması', ctrl: _descriptionCtrl, icon: Icons.description_outlined, maxLines: 4),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // ── Hizmet Alanları ───────────────────────────────────
                  const Row(
                    children: [
                      Icon(Icons.build_circle_outlined, size: 14, color: AppColors.gray500),
                      SizedBox(width: 6),
                      Text('Hizmet Alanları', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('İşletmenizin ilgilendiği alanları seçin', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kServiceAreas.map((a) {
                      final isSelected = _selectedServiceAreas.contains(a.key);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedServiceAreas = _selectedServiceAreas.where((k) => k != a.key).toList();
                          } else {
                            _selectedServiceAreas = [..._selectedServiceAreas, a.key];
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.blue600 : AppColors.gray100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.blue600 : AppColors.gray200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(a.icon, size: 14, color: isSelected ? Colors.white : AppColors.gray500),
                              const SizedBox(width: 5),
                              Text(
                                a.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.gray700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // ── Çalışma Saatleri ─────────────────────────────────
                  const Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 14, color: AppColors.gray500),
                      SizedBox(width: 6),
                      Text('Çalışma Saatleri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...[
                    ('monday',    'Pazartesi'),
                    ('tuesday',   'Salı'),
                    ('wednesday', 'Çarşamba'),
                    ('thursday',  'Perşembe'),
                    ('friday',    'Cuma'),
                    ('saturday',  'Cumartesi'),
                    ('sunday',    'Pazar'),
                  ].map((d) {
                    final (key, label) = d;
                    final day = _workingHours[key]!;
                    final isOpen = day['isOpen'] as bool;
                    final openTime  = day['open']  as String;
                    final closeTime = day['close'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 88,
                            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray700, fontWeight: FontWeight.w500)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _workingHours[key] = {...day, 'isOpen': !isOpen}),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isOpen ? AppColors.primary600 : AppColors.gray200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOpen ? 'Açık' : 'Kapalı',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen ? Colors.white : AppColors.gray500,
                                ),
                              ),
                            ),
                          ),
                          if (isOpen) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _pickTime(key, 'open', openTime),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  border: Border.all(color: AppColors.gray200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(openTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text('–', style: TextStyle(color: AppColors.gray400)),
                            ),
                            GestureDetector(
                              onTap: () => _pickTime(key, 'close', closeTime),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  border: Border.all(color: AppColors.gray200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(closeTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
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
                    onPressed: saving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: const BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w600)),
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

// ─── Logout Button ───────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.red50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.red100),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 18, color: AppColors.red700),
            SizedBox(width: 8),
            Text(
              'Çıkış Yap',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.red700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Row ──────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

// ─── Password Change Sheet ───────────────────────────────────────────────────

class _PasswordChangeSheet extends StatefulWidget {
  final Future<String?> Function(String current, String newPwd) onSave;

  const _PasswordChangeSheet({required this.onSave});

  @override
  State<_PasswordChangeSheet> createState() => _PasswordChangeSheetState();
}

class _PasswordChangeSheetState extends State<_PasswordChangeSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Lütfen tüm alanları doldurun');
      return;
    }

    if (newPwd.length < 6) {
      setState(() => _error = 'Yeni şifre en az 6 karakter olmalıdır');
      return;
    }

    if (newPwd != confirm) {
      setState(() => _error = 'Yeni şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final err = await widget.onSave(current, newPwd);

    if (mounted) {
      setState(() => _submitting = false);
      if (err != null) {
        setState(() => _error = err);
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreniz başarıyla güncellendi'),
            backgroundColor: AppColors.primary600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.blue600),
              SizedBox(width: 8),
              Text('Şifre Değiştir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.red700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: AppColors.red700, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildField(
            controller: _currentCtrl,
            label: 'Mevcut Şifre',
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _newCtrl,
            label: 'Yeni Şifre (En az 6 karakter)',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _confirmCtrl,
            label: 'Yeni Şifre Tekrar',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('İptal', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Şifreyi Güncelle', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.gray400),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

