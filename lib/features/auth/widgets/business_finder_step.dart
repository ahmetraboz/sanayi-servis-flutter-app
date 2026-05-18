import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/theme.dart';

class BusinessFinderResult {
  final String companyName;
  final String address;
  final String city;
  final String district;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String? googlePlaceId;
  final Map<String, dynamic>? workingHours;

  const BusinessFinderResult({
    required this.companyName,
    required this.address,
    required this.city,
    required this.district,
    required this.phone,
    this.latitude,
    this.longitude,
    this.googlePlaceId,
    this.workingHours,
  });

  bool get isValid =>
      companyName.trim().isNotEmpty && city.trim().isNotEmpty && district.trim().isNotEmpty;

  BusinessFinderResult copyWith({
    String? companyName,
    String? address,
    String? city,
    String? district,
    String? phone,
    double? latitude,
    double? longitude,
    String? googlePlaceId,
    Map<String, dynamic>? workingHours,
  }) {
    return BusinessFinderResult(
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      workingHours: workingHours ?? this.workingHours,
    );
  }
}

class _Suggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  const _Suggestion({required this.placeId, required this.mainText, required this.secondaryText});
}

class BusinessFinderStep extends ConsumerStatefulWidget {
  final ValueChanged<BusinessFinderResult?> onChanged;

  const BusinessFinderStep({super.key, required this.onChanged});

  @override
  ConsumerState<BusinessFinderStep> createState() => _BusinessFinderStepState();
}

class _BusinessFinderStepState extends ConsumerState<BusinessFinderStep>
    with SingleTickerProviderStateMixin {
  static const _turkeyCenter = LatLng(39.9334, 32.8597);

  late final TabController _tabController;

  // ─── Google search tab state ────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<_Suggestion> _suggestions = [];
  bool _searchingPlaces = false;
  bool _loadingDetails = false;
  Timer? _searchDebounce;
  BusinessFinderResult? _googleResult;

  // ─── Manual tab state ───────────────────────────────────────────────────────
  final _manualCompanyCtrl = TextEditingController();
  final _manualAddressCtrl = TextEditingController();
  final _manualCityCtrl = TextEditingController();
  final _manualDistrictCtrl = TextEditingController();
  final _manualPhoneCtrl = TextEditingController();
  LatLng? _manualPin;
  bool _reverseGeocoding = false;

  // ─── Map controllers ────────────────────────────────────────────────────────
  GoogleMapController? _googleMapCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_emitResult);
    _manualCompanyCtrl.addListener(_emitResult);
    _manualCityCtrl.addListener(_emitResult);
    _manualDistrictCtrl.addListener(_emitResult);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _manualCompanyCtrl.dispose();
    _manualAddressCtrl.dispose();
    _manualCityCtrl.dispose();
    _manualDistrictCtrl.dispose();
    _manualPhoneCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  BusinessFinderResult get _currentManualResult => BusinessFinderResult(
        companyName: _manualCompanyCtrl.text.trim(),
        address: _manualAddressCtrl.text.trim(),
        city: _manualCityCtrl.text.trim(),
        district: _manualDistrictCtrl.text.trim(),
        phone: _manualPhoneCtrl.text.trim(),
        latitude: _manualPin?.latitude,
        longitude: _manualPin?.longitude,
        googlePlaceId: null,
      );

  void _emitResult() {
    final result = _tabController.index == 0 ? _googleResult : _currentManualResult;
    widget.onChanged(result != null && result.isValid ? result : null);
  }

  // ─── Google Search Tab ──────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () => _fetchSuggestions(value));
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() => _searchingPlaces = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/public/places/autocomplete', queryParameters: {'input': input});
      final data = (res.data['suggestions'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _suggestions = data
            .map((m) => _Suggestion(
                  placeId: m['placeId'] as String? ?? '',
                  mainText: m['mainText'] as String? ?? '',
                  secondaryText: m['secondaryText'] as String? ?? '',
                ))
            .toList();
      });
    } on DioException catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _searchingPlaces = false);
    }
  }

  Future<void> _selectSuggestion(_Suggestion s) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loadingDetails = true;
      _suggestions = [];
      _searchCtrl.text = s.mainText;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/public/places/details', queryParameters: {'placeId': s.placeId});
      final d = res.data as Map<String, dynamic>;
      final result = BusinessFinderResult(
        companyName: d['name'] as String? ?? '',
        address: d['formattedAddress'] as String? ?? '',
        city: d['city'] as String? ?? '',
        district: d['district'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        latitude: (d['latitude'] as num?)?.toDouble(),
        longitude: (d['longitude'] as num?)?.toDouble(),
        googlePlaceId: d['placeId'] as String? ?? s.placeId,
        workingHours: d['workingHours'] as Map<String, dynamic>?,
      );
      if (!mounted) return;
      setState(() => _googleResult = result);
      _emitResult();
      if (result.latitude != null && result.longitude != null) {
        await _googleMapCtrl?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(result.latitude!, result.longitude!), 16),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yer detayları alınamadı'), backgroundColor: AppColors.red700),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  void _clearGoogleSelection() {
    setState(() {
      _googleResult = null;
      _searchCtrl.clear();
      _suggestions = [];
    });
    _emitResult();
  }

  // ─── Manual Tab ─────────────────────────────────────────────────────────────

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _manualPin = point;
      _reverseGeocoding = true;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(
        '/api/public/places/reverse-geocode',
        queryParameters: {'lat': '${point.latitude}', 'lng': '${point.longitude}'},
      );
      final d = res.data as Map<String, dynamic>;
      final city = d['city'] as String? ?? '';
      final district = d['district'] as String? ?? '';
      final address = d['formattedAddress'] as String? ?? '';
      if (!mounted) return;
      setState(() {
        if (city.isNotEmpty) _manualCityCtrl.text = city;
        if (district.isNotEmpty) _manualDistrictCtrl.text = district;
        if (address.isNotEmpty && _manualAddressCtrl.text.isEmpty) _manualAddressCtrl.text = address;
      });
      _emitResult();
    } on DioException catch (_) {
      // sessizce geç — kullanıcı manuel doldurabilir
    } finally {
      if (mounted) setState(() => _reverseGeocoding = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.gray900,
            unselectedLabelColor: AppColors.gray500,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 16),
                    SizedBox(width: 6),
                    Text("Google'da Ara"),
                  ],
                ),
              ),
              Tab(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Haritada Seç'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 540,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGoogleTab(),
              _buildManualTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'İşletme adı veya adresi ile arayın…',
            prefixIcon: const Icon(Icons.search, color: AppColors.gray400, size: 20),
            suffixIcon: _searchingPlaces
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue600)),
                  )
                : (_searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.gray400),
                        onPressed: _clearGoogleSelection,
                      )
                    : null),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.gray100),
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.gray400),
                  title: Text(s.mainText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(s.secondaryText, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          )
        else if (_loadingDetails)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary600, strokeWidth: 2)),
          )
        else if (_googleResult != null)
          _buildSelectedPlaceCard(_googleResult!),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: _turkeyCenter, zoom: 6),
              onMapCreated: (c) => _googleMapCtrl = c,
              markers: _googleResult != null && _googleResult!.latitude != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: LatLng(_googleResult!.latitude!, _googleResult!.longitude!),
                      ),
                    }
                  : const {},
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPlaceCard(BusinessFinderResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary600.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary600.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.companyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                if (result.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(result.address, style: const TextStyle(fontSize: 12, color: AppColors.gray500), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (result.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(result.phone, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.gray400),
            onPressed: _clearGoogleSelection,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                if (_reverseGeocoding)
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue600))
                else
                  const Icon(Icons.touch_app_outlined, size: 16, color: Color(0xFF0369A1)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Haritada işletmenizin konumuna tıklayın',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _manualField(label: 'İşletme Adı *', ctrl: _manualCompanyCtrl, icon: Icons.business_outlined),
          const SizedBox(height: 10),
          _manualField(label: 'Adres', ctrl: _manualAddressCtrl, icon: Icons.location_on_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _manualField(label: 'İl *', ctrl: _manualCityCtrl, icon: Icons.map_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _manualField(label: 'İlçe *', ctrl: _manualDistrictCtrl, icon: Icons.map_outlined)),
            ],
          ),
          const SizedBox(height: 10),
          _manualField(label: 'Telefon', ctrl: _manualPhoneCtrl, icon: Icons.phone_outlined, keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: _turkeyCenter, zoom: 6),
                onTap: _onMapTap,
                markers: _manualPin != null
                    ? {Marker(markerId: const MarkerId('manual'), position: _manualPin!)}
                    : const {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 13, color: AppColors.gray900),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: AppColors.gray400),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary600)),
          ),
        ),
      ],
    );
  }
}
