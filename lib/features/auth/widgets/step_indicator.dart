import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isEven) {
          final step = i ~/ 2 + 1;
          return _StepCircle(step: step, currentStep: currentStep);
        } else {
          final stepBefore = i ~/ 2 + 1;
          final isCompleted = currentStep > stepBefore;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.primary600 : AppColors.gray200,
            ),
          );
        }
      }),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int step;
  final int currentStep;

  const _StepCircle({required this.step, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentStep > step;
    final isActive = currentStep == step;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive ? AppColors.primary600 : AppColors.gray100,
        border: Border.all(
          color: isCompleted || isActive ? AppColors.primary600 : AppColors.gray200,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '$step',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.gray400,
                ),
              ),
      ),
    );
  }
}
