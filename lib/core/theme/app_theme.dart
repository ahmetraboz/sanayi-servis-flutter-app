import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary600,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkCard,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary600),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.red700),
          ),
          hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
          labelStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary600,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary600,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppColors.primary600),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary600,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        cardTheme: const CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: AppColors.darkBorder),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
          space: 1,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkCard,
          indicatorColor: AppColors.primary600.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary600;
            return Colors.transparent;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.gray500;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary600;
            return AppColors.darkBorder;
          }),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
          bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
          bodySmall: TextStyle(color: AppColors.darkTextMuted),
          titleLarge: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary600,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.gray50,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray900,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
          labelStyle: const TextStyle(color: AppColors.gray500, fontSize: 14),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.gray900),
          bodyMedium: TextStyle(color: AppColors.gray900, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.gray700),
          titleLarge: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary600,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary600,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppColors.primary600),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary600,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.gray200),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.gray100,
          thickness: 1,
          space: 1,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary600;
            return Colors.transparent;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.gray300;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary600;
            return AppColors.gray200;
          }),
        ),
      );
}
