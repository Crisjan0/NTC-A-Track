import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// A full-width glossy gradient button with an optional loading spinner and a
/// soft specular highlight on top — the liquid-glass take on a primary action.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final LinearGradient? gradient;
  final double? width;  // Optional width control

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient,
    this.width,  // Default to null for auto-sizing
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Center(
      child: SizedBox(
        width: width ?? double.infinity,
        height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? AppGradients.primary,
          borderRadius: BorderRadius.circular(kButtonRadius),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kButtonRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Specular highlight sweeping across the top of the button.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white38,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled ? onPressed : null,
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
