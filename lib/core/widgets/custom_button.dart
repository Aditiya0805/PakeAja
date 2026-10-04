import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Widget child;
    if (isLoading) {
      child = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary
                ? Colors.white
                : AppTheme.primaryColor,
          ),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else {
      child = Text(text);
    }

    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(width ?? double.infinity, height)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    switch (variant) {
      case ButtonVariant.primary:
        return FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: style,
          child: child,
        );
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: style,
          child: child,
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: style,
          child: child,
        );
      case ButtonVariant.danger:
        return FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: style.copyWith(
            backgroundColor:
                WidgetStateProperty.all(AppTheme.errorColor),
          ),
          child: child,
        );
    }
  }
}

enum ButtonVariant { primary, outline, text, danger }
