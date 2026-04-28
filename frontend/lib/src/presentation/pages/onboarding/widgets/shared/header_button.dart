import 'package:flutter/material.dart';

class HeaderButton extends StatefulWidget {
  final String text;
  final bool hasDropdown;
  final bool isHovered;
  final VoidCallback onPressed;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;
  final List<DropdownItem>? dropdownItems;
  final double dropdownWidth;
  final Alignment dropdownAlignment;
  final EdgeInsets dropdownPadding;

  const HeaderButton({
    super.key,
    required this.text,
    this.hasDropdown = false,
    this.isHovered = false,
    required this.onPressed,
    this.onHoverEnter,
    this.onHoverExit,
    this.dropdownItems,
    this.dropdownWidth = 280,
    this.dropdownAlignment = Alignment.topCenter,
    this.dropdownPadding = EdgeInsets.zero,
  });

  @override
  State<HeaderButton> createState() => _HeaderButtonState();
}

class DropdownItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const DropdownItem({
    required this.title,
    this.subtitle,
    this.icon,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });
}

class _HeaderButtonState extends State<HeaderButton> {
  bool _showDropdown = false;
  late final GlobalKey _buttonKey =
      GlobalKey(debugLabel: 'HeaderButton_${widget.text}');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onHoverEnter?.call();
              if (widget.hasDropdown && widget.dropdownItems != null) {
                setState(() => _showDropdown = true);
              }
            }
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onHoverExit?.call();
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) setState(() => _showDropdown = false);
              });
            }
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Stack(
          children: [
            // Main button
            Container(
              key: _buttonKey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isHovered
                    ? colorScheme.onPrimary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: _showDropdown
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  if (widget.hasDropdown) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _showDropdown
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      size: 18,
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),

            // Dropdown (slide-in from left margin style)
            if (_showDropdown && widget.dropdownItems != null)
              Positioned(
                top: 0,
                left: -widget.dropdownWidth - 8, // slide in from left margin
                child: MouseRegion(
                  onEnter: (_) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _showDropdown = true);
                      });
                    }
                  },
                  onExit: (_) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) setState(() => _showDropdown = false);
                          });
                        }
                      });
                    }
                  },
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    child: Container(
                      width: widget.dropdownWidth,
                      padding: widget.dropdownPadding,
                      decoration: BoxDecoration(
                        color:
                            isDark ? colorScheme.surface : colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 4,
                            offset: const Offset(-4, 4),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Optional arrow pointing left
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8, top: 12, bottom: 4),
                            child: Transform.rotate(
                              angle: 3.14159, // 180 degrees
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? colorScheme.surface
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                          // Dropdown items (including Custom Selection)
                          ...widget.dropdownItems!.map((item) {
                            return _buildDropdownItem(
                              context,
                              item: item,
                              isLast: widget.dropdownItems!.indexOf(item) ==
                                  widget.dropdownItems!.length - 1,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem(
    BuildContext context, {
    required DropdownItem item,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          item.onTap();
          setState(() => _showDropdown = false);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            children: [
              if (item.icon != null)
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: item.iconColor ?? colorScheme.primary,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.textColor ?? colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
