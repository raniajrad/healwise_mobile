import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double borderRadius;
  final EdgeInsets padding;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.height = 52,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBgColor =
        backgroundColor ??
        (isOutlined ? Colors.transparent : AppTheme.primaryColor);
    final effectiveTextColor = textColor ?? Colors.white;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveTextColor,
          disabledBackgroundColor: effectiveBgColor.withOpacity(0.6),
          disabledForegroundColor: effectiveTextColor.withOpacity(0.6),
          elevation: isOutlined ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isOutlined
                ? BorderSide(color: AppTheme.primaryColor, width: 1.5)
                : BorderSide.none,
          ),
          padding: padding,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: effectiveTextColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: effectiveTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Usage examples:
// CustomButton(text: 'Primary', onPressed: () {})
// CustomButton(text: 'Outlined', onPressed: () {}, isOutlined: true)
// CustomButton(text: 'Loading', isLoading: true)
// CustomButton(text: 'With Icon', icon: Icons.save, onPressed: () {})
