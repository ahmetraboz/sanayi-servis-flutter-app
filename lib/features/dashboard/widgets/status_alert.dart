import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/theme.dart';

class ProviderStatusAlert extends ConsumerWidget {
  const ProviderStatusAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final status = user?.serviceProfile?['status'] as String?;

    if (status == null) return const SizedBox.shrink();

    return switch (status) {
      'pending' => _AlertBanner(
          icon: Icons.hourglass_empty_outlined,
          iconColor: AppColors.amber700,
          backgroundColor: AppColors.warning50,
          borderColor: const Color(0xFFFDE68A),
          title: 'Hesabınız İnceleniyor',
          message: 'Servis profiliniz admin onayı bekliyor. Onaylandıktan sonra taleplere teklif verebilirsiniz.',
        ),
      'rejected' => _AlertBanner(
          icon: Icons.cancel_outlined,
          iconColor: AppColors.red700,
          backgroundColor: AppColors.red50,
          borderColor: AppColors.red100,
          title: 'Hesabınız Reddedildi',
          message: 'Profiliniz onaylanmadı. Detaylar için destek ekibiyle iletişime geçin.',
          actionLabel: 'Destek Al',
          onAction: () => context.go('/provider/profile'),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AlertBanner({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray700,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                        decoration: TextDecoration.underline,
                        decorationColor: iconColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
