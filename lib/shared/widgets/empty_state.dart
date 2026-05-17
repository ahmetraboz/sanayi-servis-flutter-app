import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: AppColors.gray300),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: const TextStyle(fontSize: 13, color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
