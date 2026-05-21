import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../data/turkey_locations.dart';

Future<String?> showCityPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _LocationSheet(title: 'İl Seçin', items: null, cityForDistricts: null),
  );
}

Future<String?> showDistrictPicker(BuildContext context, String city) {
  final loc = turkeyLocations.where((l) => l.city == city).firstOrNull;
  if (loc == null) return Future.value(null);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _LocationSheet(title: 'İlçe Seçin', items: loc.districts, cityForDistricts: city),
  );
}

class _LocationSheet extends StatefulWidget {
  final String title;
  final List<String>? items;
  final String? cityForDistricts;

  const _LocationSheet({required this.title, required this.items, required this.cityForDistricts});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<String> get _filtered {
    final list = widget.items ?? turkeyLocations.map((l) => l.city).toList();
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenH * 0.85,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Ara...',
                hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.gray400, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.gray400),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue600, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.gray100),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('Sonuç bulunamadı', style: TextStyle(color: AppColors.gray400)))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      return InkWell(
                        onTap: () => Navigator.pop(context, item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gray400),
                              const SizedBox(width: 10),
                              Text(item, style: const TextStyle(fontSize: 15, color: AppColors.gray700)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Seçim butonunu gösteren yardımcı widget
class LocationPickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final bool enabled;
  final VoidCallback onTap;

  const LocationPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: value != null ? AppColors.blue600 : AppColors.gray200),
            ),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 16, color: enabled ? AppColors.gray400 : AppColors.gray300),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 13,
                      color: value != null ? AppColors.gray900 : AppColors.gray400,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: enabled ? AppColors.gray400 : AppColors.gray300),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
