import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/constants/turkey_cities.dart';
import '../../core/theme/theme.dart';
import '../../shared/widgets/app_select_field.dart';
import 'widgets/step_indicator.dart';
import 'widgets/vehicle_form_step.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  String? _selectedRole;
  int _currentStep = 1;

  // Step 1 form
  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _showPassword = false;

  // Customer step 2
  final _vehicleData = VehicleFormData();

  // Provider steps 2 & 3
  final _step2ProviderKey = GlobalKey<FormState>();
  final _step3ProviderKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _pCityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedProviderCity;

  bool _loading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _pCityCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    _taxCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _selectRole(String role) => setState(() => _selectedRole = role);

  void _nextStep() {
    if (_currentStep == 1) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
    }
    if (_selectedRole == 'customer' && _currentStep == 2) {
      if (!_vehicleData.isValid) {
        setState(() => _errorMessage = 'Lütfen marka, model ve yılı doldurun');
        return;
      }
    }
    if (_selectedRole == 'provider' && _currentStep == 2) {
      if (!(_step2ProviderKey.currentState?.validate() ?? false)) return;
      if (_selectedProviderCity == null) {
        setState(() => _errorMessage = 'Lütfen şehir seçin');
        return;
      }
    }
    if (_selectedRole == 'provider' && _currentStep == 3) {
      if (!(_step3ProviderKey.currentState?.validate() ?? false)) return;
    }
    setState(() {
      _errorMessage = '';
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 1) setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      final isProvider = _selectedRole == 'provider';
      await ref.read(authNotifierProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            phone: _phoneCtrl.text.trim(),
            role: _selectedRole!,
            vehicle: isProvider ? null : _vehicleData.toJson(),
            serviceProfile: isProvider
                ? {
                    'companyName': _companyCtrl.text.trim(),
                    'city': _selectedProviderCity,
                    'district': _districtCtrl.text.trim(),
                    'address': _addressCtrl.text.trim(),
                    if (_taxCtrl.text.trim().isNotEmpty) 'taxNumber': _taxCtrl.text.trim(),
                    if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
                  }
                : null,
          );
      // GoRouter redirect handles navigation automatically via authNotifierProvider
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () {
            if (_selectedRole != null) {
              if (_currentStep > 1) {
                _prevStep();
              } else {
                setState(() => _selectedRole = null);
              }
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          _selectedRole == null ? 'Kayıt Ol' : _stepTitle(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _selectedRole == null
            ? _buildRoleSelector()
            : _selectedRole == 'customer'
                ? _buildCustomerFlow()
                : _buildProviderFlow(),
      ),
    );
  }

  String _stepTitle() {
    if (_selectedRole == 'provider') {
      return switch (_currentStep) {
        1 => 'Kişisel Bilgiler',
        2 => 'İşletme Bilgileri',
        3 => 'Detaylar',
        4 => 'Onay',
        _ => 'Kayıt Ol',
      };
    }
    return switch (_currentStep) {
      1 => 'Kişisel Bilgiler',
      2 => 'Araç Bilgisi',
      3 => 'Onay',
      _ => 'Kayıt Ol',
    };
  }

  // ── Role Selector ──────────────────────────────────────────────────────────

  Widget _buildRoleSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 24),
          const Text(
            'Nasıl kullanmak istiyorsunuz?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.gray900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hesap türünüzü seçin',
            style: TextStyle(fontSize: 15, color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                _RoleCard(
                  icon: Icons.directions_car,
                  title: 'Araç Sahibiyim',
                  description: 'Servis ihtiyaçlarım için teklif almak istiyorum',
                  onTap: () => _selectRole('customer'),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.build,
                  title: 'Servis Sağlayıcıyım',
                  description: 'Servis işletmem için müşteri bulmak istiyorum',
                  onTap: () => _selectRole('provider'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Zaten hesabınız var mı? ', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Giriş yapın',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Customer 3-Step Flow ───────────────────────────────────────────────────

  Widget _buildCustomerFlow() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepIndicator(totalSteps: 3, currentStep: _currentStep),
            const SizedBox(height: 28),
            if (_errorMessage.isNotEmpty) ...[
              _buildErrorAlert(),
              const SizedBox(height: 16),
            ],
            _buildCurrentStep(),
            const SizedBox(height: 24),
            _buildStepActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() => switch (_currentStep) {
        1 => _buildStep1(),
        2 => _buildStep2(),
        3 => _buildStep3(),
        _ => const SizedBox(),
      };

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            label: 'Ad Soyad',
            child: TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(hint: 'Ahmet Yılmaz', prefixIcon: Icons.person_outline),
              validator: (v) => (v?.trim().length ?? 0) < 2 ? 'En az 2 karakter giriniz' : null,
            ),
          ),
          const SizedBox(height: 20),
          _labeledField(
            label: 'E-posta',
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(hint: 'ornek@email.com', prefixIcon: Icons.email_outlined),
              validator: (v) => (v?.contains('@') ?? false) ? null : 'Geçerli e-posta giriniz',
            ),
          ),
          const SizedBox(height: 20),
          _labeledField(
            label: 'Şifre',
            child: TextFormField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.gray400,
                    size: 20,
                  ),
                ),
              ),
              validator: (v) => (v?.length ?? 0) < 6 ? 'En az 6 karakter giriniz' : null,
            ),
          ),
          const SizedBox(height: 20),
          _labeledField(
            label: 'Telefon (isteğe bağlı)',
            child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(hint: '5XX XXX XXXX', prefixIcon: Icons.phone_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return VehicleFormStep(
      data: _vehicleData,
      onChanged: () => setState(() {}),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bilgilerinizi Onaylayın',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        const SizedBox(height: 20),
        _SummaryCard(
          title: 'Kişisel Bilgiler',
          icon: Icons.person_outline,
          rows: [
            _SummaryRow('Ad Soyad', _nameCtrl.text),
            _SummaryRow('E-posta', _emailCtrl.text),
            if (_phoneCtrl.text.isNotEmpty) _SummaryRow('Telefon', _phoneCtrl.text),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: 'Araç Bilgileri',
          icon: Icons.directions_car_outlined,
          rows: [
            _SummaryRow('Marka / Model', '${_vehicleData.brand} ${_vehicleData.model}'),
            _SummaryRow('Yıl', _vehicleData.year),
            if (_vehicleData.licensePlate.isNotEmpty)
              _SummaryRow('Plaka', _vehicleData.licensePlate),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.blue600, size: 18),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Hesabınız oluşturulduktan sonra servis taleplerini iletebilirsiniz.',
                  style: TextStyle(fontSize: 13, color: AppColors.blue600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepActions() {
    final isLastStep = _currentStep == 3;
    return Column(
      children: [
        GestureDetector(
          onTap: _loading ? null : (isLastStep ? _submit : _nextStep),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary600, AppColors.primaryTeal],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary600.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isLastStep ? 'Hesap Oluştur' : 'İleri',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('İleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  // ── Provider Flow ──────────────────────────────────────────────────────────

  Widget _buildProviderFlow() {
    if (_currentStep == 1) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepIndicator(totalSteps: 4, currentStep: 1),
            const SizedBox(height: 28),
            if (_errorMessage.isNotEmpty) ...[_buildErrorAlert(), const SizedBox(height: 16)],
            _buildStep1(),
            const SizedBox(height: 24),
            _buildStepActions(),
          ],
        ),
      );
    }
    return switch (_currentStep) {
      2 => _buildProviderStep2(),
      3 => _buildProviderStep3(),
      _ => _buildProviderSummary(),
    };
  }

  Widget _buildProviderStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2ProviderKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepIndicator(currentStep: 2, totalSteps: 4),
            const SizedBox(height: 24),
            _labeledField(
              label: 'Şirket Adı',
              child: TextFormField(
                controller: _companyCtrl,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration(hint: 'Örn: Ahmet Oto Servis', prefixIcon: Icons.business_outlined),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Şirket adı zorunlu' : null,
              ),
            ),
            const SizedBox(height: 16),
            _labeledField(
              label: 'Şehir',
              child: AppSelectField(
                options: kTurkeyCities,
                value: _selectedProviderCity,
                hintText: 'Şehir seçin',
                decoration: _inputDecoration(hint: 'Şehir seçin', prefixIcon: Icons.location_city_outlined),
                onChanged: (v) => setState(() => _selectedProviderCity = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Şehir seçin' : null,
              ),
            ),
            const SizedBox(height: 16),
            _labeledField(
              label: 'İlçe',
              child: TextFormField(
                controller: _districtCtrl,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration(hint: 'İlçe adı', prefixIcon: Icons.location_city_outlined),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'İlçe zorunlu' : null,
              ),
            ),
            const SizedBox(height: 16),
            _labeledField(
              label: 'Adres',
              child: TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration(hint: 'Açık adres', prefixIcon: Icons.map_outlined),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Adres zorunlu' : null,
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 16), _buildErrorAlert()],
            const SizedBox(height: 24),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step3ProviderKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepIndicator(currentStep: 3, totalSteps: 4),
            const SizedBox(height: 24),
            _labeledField(
              label: 'Vergi Numarası (opsiyonel)',
              child: TextFormField(
                controller: _taxCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration(hint: '10 haneli vergi numarası', prefixIcon: Icons.receipt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            _labeledField(
              label: 'İşletme Açıklaması (opsiyonel)',
              child: TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration(hint: 'Hizmetleriniz, uzmanlık alanlarınız…'),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF0369A1)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hesabınız admin onayı bekleyecek. Onaylandıktan sonra taleplere teklif verebilirsiniz.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 16), _buildErrorAlert()],
            const SizedBox(height: 24),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepIndicator(currentStep: 4, totalSteps: 4),
          const SizedBox(height: 24),
          const Text('Bilgilerinizi Onaylayın',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(height: 8),
          const Text('Kayıt olmadan önce bilgilerinizi kontrol edin.',
              style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          const SizedBox(height: 20),
          _SummaryCard(
            title: 'Kişisel Bilgiler',
            icon: Icons.person_outline,
            rows: [
              _SummaryRow('Ad Soyad', _nameCtrl.text.trim()),
              _SummaryRow('E-posta', _emailCtrl.text.trim()),
              _SummaryRow('Telefon', _phoneCtrl.text.trim()),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'İşletme Bilgileri',
            icon: Icons.business_outlined,
            rows: [
              _SummaryRow('Şirket Adı', _companyCtrl.text.trim()),
              _SummaryRow('Şehir', _selectedProviderCity ?? ''),
              _SummaryRow('İlçe', _districtCtrl.text.trim()),
              _SummaryRow('Adres', _addressCtrl.text.trim()),
              if (_taxCtrl.text.trim().isNotEmpty) _SummaryRow('Vergi No', _taxCtrl.text.trim()),
            ],
          ),
          if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 16), _buildErrorAlert()],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Kayıt Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Helpers ─────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.build, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text('Sanayi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.gray900)),
      ],
    );
  }

  Widget _buildErrorAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _errorMessage,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.gray400, size: 20) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
    );
  }
}

// ── Sub-Widgets ──────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
          color: AppColors.gray50,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary600.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_SummaryRow> rows;

  const _SummaryCard({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary600),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray100),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                    Text(r.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
