import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/app_select_field.dart';

class VehicleFormData {
  String brand;
  String model;
  String year;
  String licensePlate;

  VehicleFormData({
    this.brand = '',
    this.model = '',
    this.year = '',
    this.licensePlate = '',
  });

  bool get isValid => brand.isNotEmpty && model.isNotEmpty && year.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'year': int.tryParse(year) ?? 0,
        'licensePlate': licensePlate,
      };
}

const _kBrands = [
  'Toyota', 'Honda', 'Ford', 'Volkswagen', 'Renault', 'Fiat',
  'Peugeot', 'BMW', 'Mercedes-Benz', 'Audi', 'Hyundai', 'Kia',
  'Opel', 'Skoda', 'Seat', 'Volvo', 'Nissan', 'Mitsubishi',
  'Suzuki', 'Dacia', 'Citroen', 'Mazda', 'Subaru', 'Jeep',
  'Land Rover', 'Porsche', 'TOGG', 'Diğer',
];

class VehicleFormStep extends StatefulWidget {
  final VehicleFormData data;
  final VoidCallback? onChanged;

  const VehicleFormStep({super.key, required this.data, this.onChanged});

  @override
  State<VehicleFormStep> createState() => _VehicleFormStepState();
}

class _VehicleFormStepState extends State<VehicleFormStep> {
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _plateCtrl;

  @override
  void initState() {
    super.initState();
    _modelCtrl = TextEditingController(text: widget.data.model);
    _yearCtrl = TextEditingController(text: widget.data.year);
    _plateCtrl = TextEditingController(text: widget.data.licensePlate);
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged?.call();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Marka'),
        const SizedBox(height: 6),
        AppSelectField(
          options: _kBrands,
          value: widget.data.brand.isEmpty ? null : widget.data.brand,
          hintText: 'Marka seçin',
          decoration: _inputDecoration(),
          onChanged: (v) {
            setState(() => widget.data.brand = v ?? '');
            _notify();
          },
          validator: (v) => (v == null || v.isEmpty) ? 'Marka zorunludur' : null,
        ),
        const SizedBox(height: 20),
        _label('Model'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _modelCtrl,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: AppColors.gray900, fontSize: 14),
          onChanged: (v) {
            widget.data.model = v;
            _notify();
          },
          decoration: _inputDecoration(hint: 'Örn: Corolla'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Yıl'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                    onChanged: (v) {
                      widget.data.year = v;
                      _notify();
                    },
                    decoration: _inputDecoration(hint: '2020'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Plaka'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                    onChanged: (v) {
                      widget.data.licensePlate = v.toUpperCase();
                      _plateCtrl.value = _plateCtrl.value.copyWith(
                        text: v.toUpperCase(),
                        selection: TextSelection.collapsed(offset: v.length),
                      );
                      _notify();
                    },
                    decoration: _inputDecoration(hint: '34 ABC 123'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary600),
        ),
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
      );
}
