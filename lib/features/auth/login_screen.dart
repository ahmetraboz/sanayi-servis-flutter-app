import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Lütfen tüm alanları doldurun');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      await ref.read(authNotifierProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
      // GoRouter redirect handles navigation automatically via authNotifierProvider
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString().isNotEmpty
          ? e.toString()
          : 'E-posta veya şifre hatalı');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _redirectPath(String role) => switch (role) {
        'provider' => '/provider',
        'admin' => '/admin',
        _ => '/dashboard',
      };

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 768;
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: 32),
            _buildHeader(),
            const SizedBox(height: 24),
            if (_errorMessage.isNotEmpty) ...[
              _buildErrorAlert(),
              const SizedBox(height: 16),
            ],
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildBrandPanel()),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty) ...[
                    _buildErrorAlert(),
                    const SizedBox(height: 16),
                  ],
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary600, AppColors.primaryTeal],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.build, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          'Sanayi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoş geldiniz',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hesabınıza giriş yapın',
          style: TextStyle(fontSize: 16, color: AppColors.gray500),
        ),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('E-posta'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.gray900, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'ornek@email.com',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gray400, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          _buildInputLabel('Şifre'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onSubmit(),
            style: const TextStyle(color: AppColors.gray900, fontSize: 14),
            decoration: _inputDecoration(
              hint: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.gray400, size: 20),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Icon(
                  _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.gray400,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Şifremi unuttum', style: TextStyle(fontSize: 14, color: AppColors.primary600)),
            ),
          ),
          const SizedBox(height: 16),
          _buildSubmitButton(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Hesabınız yok mu? ', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: const Text(
                  'Kayıt ol',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _loading ? null : _onSubmit,
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
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Giriş yapılıyor...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary600, AppColors.primary700, AppColors.primaryTeal800],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.build, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sanayi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Text(
            'Aracınız için en iyi servisi bulun',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Onaylı servis sağlayıcılardan teklif alın.',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 40),
          _buildFeatureRow(Icons.shield_outlined, 'Güvenilir Servisler', 'Onaylı ve değerlendirilmiş'),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.price_check, 'Şeffaf Fiyatlandırma', 'Rekabetçi teklifler alın'),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.star_outline, 'Değerlendirmeli Ustalar', 'Gerçek müşteri yorumları'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon != null
          ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixIcon)
          : null,
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700),
    );
  }
}
