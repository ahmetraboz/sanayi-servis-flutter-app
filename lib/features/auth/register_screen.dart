import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme.dart';
import 'widgets/business_finder_step.dart';
import 'widgets/step_indicator.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _currentStep = 1;

  // Step 1 — personal info
  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _showPassword = false;

  // Step 2 — business finder result (Google search or manual map pick)
  BusinessFinderResult? _businessData;

  // Step 3 — extra details
  final _step3Key = GlobalKey<FormState>();
  final _taxCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _loading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _taxCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1 && !(_step1Key.currentState?.validate() ?? false)) return;
    if (_currentStep == 2) {
      if (_businessData == null) {
        setState(() => _errorMessage = 'İşletmenizi Google\'dan arayın veya haritadan seçip bilgileri tamamlayın');
        return;
      }
    }
    if (_currentStep == 3 && !(_step3Key.currentState?.validate() ?? false)) return;
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
      final b = _businessData!;
      await ref.read(authNotifierProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            phone: _phoneCtrl.text.trim(),
            role: 'provider',
            vehicle: null,
            serviceProfile: {
              'companyName': b.companyName,
              'city': b.city,
              'district': b.district,
              'address': b.address,
              if (b.phone.isNotEmpty) 'phone': b.phone,
              if (b.latitude != null) 'latitude': '${b.latitude}',
              if (b.longitude != null) 'longitude': '${b.longitude}',
              if (b.googlePlaceId != null && b.googlePlaceId!.isNotEmpty) 'googlePlaceId': b.googlePlaceId,
              if (b.workingHours != null) 'workingHours': jsonEncode(b.workingHours),
              if (_taxCtrl.text.trim().isNotEmpty) 'taxNumber': _taxCtrl.text.trim(),
              if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
            },
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
            if (_currentStep > 1) {
              _prevStep();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          _stepTitle(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildFlow()),
    );
  }

  String _stepTitle() => switch (_currentStep) {
        1 => 'Kişisel Bilgiler',
        2 => 'İşletme Bilgileri',
        3 => 'Detaylar',
        4 => 'Onay',
        _ => 'Kayıt Ol',
      };

  Widget _buildFlow() => switch (_currentStep) {
        1 => _buildStep1Container(),
        2 => _buildStep2(),
        3 => _buildStep3(),
        _ => _buildSummary(),
      };

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  Widget _buildStep1Container() {
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
          _buildPrimaryButton(label: 'İleri', onTap: _nextStep),
        ],
      ),
    );
  }

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

  // ── Step 2 — Business Info (Google search + map) ───────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepIndicator(currentStep: 2, totalSteps: 4),
          const SizedBox(height: 16),
          const Text(
            'İşletmenizi Bulun',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Google\'da arayın veya haritada konumunu seçin',
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          BusinessFinderStep(
            onChanged: (result) => setState(() => _businessData = result),
          ),
          if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 16), _buildErrorAlert()],
          const SizedBox(height: 24),
          _buildPrimaryButton(label: 'İleri', onTap: _nextStep),
        ],
      ),
    );
  }

  // ── Step 3 — Details ───────────────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step3Key,
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
            _buildPrimaryButton(label: 'İleri', onTap: _nextStep),
          ],
        ),
      ),
    );
  }

  // ── Step 4 — Summary ───────────────────────────────────────────────────────

  Widget _buildSummary() {
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
              _SummaryRow('Şirket Adı', _businessData?.companyName ?? ''),
              _SummaryRow('İl', _businessData?.city ?? ''),
              _SummaryRow('İlçe', _businessData?.district ?? ''),
              if ((_businessData?.address ?? '').isNotEmpty) _SummaryRow('Adres', _businessData!.address),
              if ((_businessData?.phone ?? '').isNotEmpty) _SummaryRow('İşletme Tel', _businessData!.phone),
              if (_businessData?.googlePlaceId != null) const _SummaryRow('Kaynak', 'Google Maps doğrulandı'),
              if (_taxCtrl.text.trim().isNotEmpty) _SummaryRow('Vergi No', _taxCtrl.text.trim()),
            ],
          ),
          if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 16), _buildErrorAlert()],
          const SizedBox(height: 24),
          _buildPrimaryButton(label: 'Kayıt Ol', onTap: _submit),
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildPrimaryButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
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
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
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

// ── Summary helpers ────────────────────────────────────────────────────────────

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
