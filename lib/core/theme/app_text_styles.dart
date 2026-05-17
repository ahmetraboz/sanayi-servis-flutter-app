import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const xs = TextStyle(fontSize: 12);
  static const sm = TextStyle(fontSize: 14);
  static const base = TextStyle(fontSize: 16);
  static const lg = TextStyle(fontSize: 18);
  static const xl = TextStyle(fontSize: 20);
  static const xl2 = TextStyle(fontSize: 24);
  static const xl3 = TextStyle(fontSize: 30);
  static const xl4 = TextStyle(fontSize: 36);
  static const xl5 = TextStyle(fontSize: 48);

  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extrabold = FontWeight.w800;

  // Convenience composites
  static const h1 = TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.gray900);
  static const h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.gray900);
  static const h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.gray900);
  static const h4 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900);
  static const body = TextStyle(fontSize: 16, color: AppColors.gray700);
  static const bodySmall = TextStyle(fontSize: 14, color: AppColors.gray500);
  static const caption = TextStyle(fontSize: 12, color: AppColors.gray400);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700);
}
