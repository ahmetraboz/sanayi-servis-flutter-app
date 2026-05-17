import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final toastServiceProvider = Provider<ToastService>((ref) => ToastService());

class ToastService {
  void showSuccess(String message) => _show(
        message,
        icon: Icons.check_circle_outline,
        iconColor: Colors.white,
        backgroundColor: AppColors.primary600,
      );

  void showError(String message) => _show(
        message,
        icon: Icons.error_outline,
        iconColor: Colors.white,
        backgroundColor: AppColors.red700,
      );

  void showInfo(String message) => _show(
        message,
        icon: Icons.info_outline,
        iconColor: Colors.white,
        backgroundColor: AppColors.blue600,
      );

  void showWarning(String message) => _show(
        message,
        icon: Icons.warning_amber_outlined,
        iconColor: Colors.white,
        backgroundColor: AppColors.amber600,
      );

  void _show(
    String message, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    scaffoldMessengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          elevation: 4,
        ),
      );
  }
}
