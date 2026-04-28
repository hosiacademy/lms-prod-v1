/// Responsive Component Library for Flutter Web LMS
///
/// Pre-built responsive components that automatically adapt to screen size
/// and follow the app's design system.

import 'package:flutter/material.dart';
import '../responsive/responsive_layout_widgets.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE BUTTON
// ─────────────────────────────────────────────────────────────────────────

/// Responsive button that adapts to screen size
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final dynamic variant;
  final double? width;
  final double? height;
  final IconData? icon;

  const ResponsiveButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? ResponsiveHelper.buttonHeight(context);
    final padding = ResponsiveHelper.padding(context);

    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    final buttonStyle = _getButtonStyle(context, variant);

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context, dynamic variantParam) {
    const borderRadius = BorderRadius.all(Radius.circular(8));

    ButtonVariant effectiveVariant = ButtonVariant.primary;
    if (variantParam is String) {
      switch (variantParam.toLowerCase()) {
        case 'secondary':
          effectiveVariant = ButtonVariant.secondary;
          break;
        case 'outline':
          effectiveVariant = ButtonVariant.outline;
          break;
        case 'text':
          effectiveVariant = ButtonVariant.text;
          break;
        case 'success':
          effectiveVariant = ButtonVariant.success;
          break;
        case 'danger':
          effectiveVariant = ButtonVariant.danger;
          break;
        default:
          effectiveVariant = ButtonVariant.primary;
          break;
      }
    } else if (variantParam is ButtonVariant) {
      effectiveVariant = variantParam;
    }

    switch (effectiveVariant) {
      case ButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.hosiPeach,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.padding(context),
          ),
        );
      case ButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.hosiBrown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.padding(context),
          ),
        );
      case ButtonVariant.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.hosiPeach,
          side: const BorderSide(color: AppTheme.hosiPeach),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.padding(context),
          ),
        );
      case ButtonVariant.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.hosiPeach,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.padding(context),
          ),
        );
      case ButtonVariant.success:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.padding(context),
          ),
        );
      case ButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.padding(context),
          ),
        );
    }
  }
}

enum ButtonVariant { primary, secondary, outline, text, success, danger }

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE CARD
// ─────────────────────────────────────────────────────────────────────────

/// Responsive card with consistent styling
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? width;
  final Color? backgroundColor;
  final bool clickable;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.width,
    this.backgroundColor,
    this.clickable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardPadding = padding ?? ResponsiveHelper.paddingAll(context);
    final borderRadius =
        BorderRadius.circular(ResponsiveHelper.borderRadius(context));
    final elevation = ResponsiveHelper.elevation(context);

    return GestureDetector(
      onTap: clickable ? onTap : null,
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        color: backgroundColor,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────

/// Responsive text field with responsive font size
class ResponsiveTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final String? errorText;

  const ResponsiveTextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = ResponsiveHelper.borderRadius(context);
    final fontSize = ResponsiveHelper.body(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppTheme.hosiPeach, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
        contentPadding: EdgeInsets.all(ResponsiveHelper.spacingMedium(context)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────

/// Section header with responsive typography
class ResponsiveSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onActionPressed;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveSectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.action,
    this.onActionPressed,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.h2(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: ResponsiveHelper.spacingSmall(context)),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.body(context),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // FIXED: Removed extra closing parenthesis and bracket
            if (action != null)
              action!
            else if (onActionPressed != null)
              TextButton(
                onPressed: onActionPressed,
                child: const Text('View All'),
              ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.spacingMedium(context)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE LIST ITEM
// ─────────────────────────────────────────────────────────────────────────

/// Responsive list item with adaptive layout
class ResponsiveListItem extends StatelessWidget {
  final Widget? leading;
  final Widget? avatar;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ResponsiveListItem({
    Key? key,
    this.leading,
    this.avatar,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayLeading = leading ?? avatar ?? const SizedBox();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.spacingMedium(context)),
        child: Row(
          children: [
            SizedBox(
              width: ResponsiveHelper.iconSize(context),
              child: displayLeading,
            ),
            SizedBox(width: ResponsiveHelper.spacingMedium(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.body(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: ResponsiveHelper.spacingSmall(context)),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.caption(context),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────

/// Empty state display with responsive sizing
class ResponsiveEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const ResponsiveEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.iconSize(context,
                size: IconSizeCategory.large),
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveHelper.spacingLarge(context)),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.h3(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description != null) ...[
            SizedBox(height: ResponsiveHelper.spacingMedium(context)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.padding(context),
              ),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveHelper.body(context),
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
          if (action != null) ...[
            SizedBox(height: ResponsiveHelper.spacingLarge(context)),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE DIALOG
// ─────────────────────────────────────────────────────────────────────────

/// Show responsive dialog with proper sizing
Future<T?> showResponsiveDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.dialogWidth(context),
          ),
          child: builder(context),
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE FORM FIELD
// ─────────────────────────────────────────────────────────────────────────

/// Responsive form field wrapper
class ResponsiveFormField extends StatelessWidget {
  final String? label;
  final Widget child;
  final String? helperText;
  final String? errorText;
  final bool required;

  const ResponsiveFormField({
    Key? key,
    this.label,
    required this.child,
    this.helperText,
    this.errorText,
    this.required = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.body(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.spacingSmall(context)),
        ],
        child,
        if (errorText != null) ...[
          SizedBox(height: ResponsiveHelper.spacingSmall(context)),
          Text(
            errorText!,
            style: const TextStyle(color: AppTheme.errorRed),
          ),
        ] else if (helperText != null) ...[
          SizedBox(height: ResponsiveHelper.spacingSmall(context)),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: ResponsiveHelper.caption(context),
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RESPONSIVE IMAGE
// ─────────────────────────────────────────────────────────────────────────

/// Responsive image with adaptive sizing
class ResponsiveImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ResponsiveImage(
    this.imageUrl, {
    Key? key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageHeight = height ?? ResponsiveHelper.imageHeight(context);
    final borderRad = borderRadius ??
        BorderRadius.circular(ResponsiveHelper.borderRadius(context));

    return ClipRRect(
      borderRadius: borderRad,
      child: Image.network(
        imageUrl,
        width: width,
        height: imageHeight,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: imageHeight,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          );
        },
      ),
    );
  }
}
