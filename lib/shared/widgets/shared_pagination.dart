import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class SharedPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int>? onPageChanged;

  const SharedPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    this.onPrevious,
    this.onNext,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    if (onPageChanged != null) {
      return _NumberedPagination(
        currentPage: currentPage,
        totalPages: totalPages,
        onPageChanged: onPageChanged!,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: [
          _NavButton(
            label: 'Önceki',
            icon: Icons.chevron_left,
            iconFirst: true,
            enabled: currentPage > 1,
            onTap: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '$total kayıt',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _NavButton(
            label: 'Sonraki',
            icon: Icons.chevron_right,
            iconFirst: false,
            enabled: currentPage < totalPages,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NumberedPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _NumberedPagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pageCount = min(totalPages, 7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: currentPage > 1 ? AppColors.primary600 : AppColors.gray300,
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          ...List.generate(pageCount, (i) {
            final page = i + 1;
            final isActive = page == currentPage;
            return _PageButton(
              page: page,
              isActive: isActive,
              onTap: () => onPageChanged(page),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: currentPage < totalPages ? AppColors.primary600 : AppColors.gray300,
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageButton({required this.page, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary600 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: AppColors.gray200),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconFirst;
  final bool enabled;
  final VoidCallback? onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primary600 : AppColors.gray300;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.success50 : AppColors.gray50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? AppColors.primary600.withValues(alpha: 0.3) : AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color))]
              : [Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)), const SizedBox(width: 4), Icon(icon, size: 16, color: color)],
        ),
      ),
    );
  }
}
