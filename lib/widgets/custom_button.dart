import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  BUTTON VARIANTS
// ─────────────────────────────────────────────

enum AppButtonVariant { primary, secondary, danger, ghost }

// ─────────────────────────────────────────────
//  APP BUTTON
// ─────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.width,
  });

  // ── STYLE PER VARIANT ─────────────────────────────────────────

  Color get _bgColor => switch (variant) {
        AppButtonVariant.primary   => const Color(0xFF2563EB),
        AppButtonVariant.secondary => Colors.white,
        AppButtonVariant.danger    => const Color(0xFFFEE2E2),
        AppButtonVariant.ghost     => Colors.transparent,
      };

  Color get _textColor => switch (variant) {
        AppButtonVariant.primary   => Colors.white,
        AppButtonVariant.secondary => const Color(0xFF374151),
        AppButtonVariant.danger    => const Color(0xFFDC2626),
        AppButtonVariant.ghost     => const Color(0xFF6B7280),
      };

  Color get _borderColor => switch (variant) {
        AppButtonVariant.primary   => const Color(0xFF2563EB),
        AppButtonVariant.secondary => const Color(0xFFE5E7EB),
        AppButtonVariant.danger    => const Color(0xFFFECACA),
        AppButtonVariant.ghost     => Colors.transparent,
      };

  Color get _hoverColor => switch (variant) {
        AppButtonVariant.primary   => const Color(0xFF1D4ED8),
        AppButtonVariant.secondary => const Color(0xFFF9FAFB),
        AppButtonVariant.danger    => const Color(0xFFFECACA),
        AppButtonVariant.ghost     => const Color(0xFFF3F4F6),
      };

  @override
  Widget build(BuildContext context) {
    final btn = _HoverButton(
      onPressed: isLoading ? null : onPressed,
      bgColor: _bgColor,
      hoverColor: _hoverColor,
      borderColor: _borderColor,
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _textColor,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: _textColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
              ],
            ),
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: btn);
    if (width != null) return SizedBox(width: width, child: btn);
    return btn;
  }
}

// ─────────────────────────────────────────────
//  APP ICON BUTTON — chỉ có icon, không có label
// ─────────────────────────────────────────────

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? bgColor;
  final String? tooltip;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.bgColor,
    this.tooltip,
    this.size = 17,
  });

  @override
  Widget build(BuildContext context) {
    final btn = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      color: color ?? const Color(0xFF9CA3AF),
      tooltip: tooltip,
      style: bgColor != null
          ? IconButton.styleFrom(backgroundColor: bgColor)
          : null,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );

    return btn;
  }
}

// ─────────────────────────────────────────────
//  TABLE ACTION BUTTONS — nhóm 3 nút view/edit/delete
// ─────────────────────────────────────────────

class TableActions extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TableActions({
    super.key,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onView != null)
          AppIconButton(
            icon: Icons.visibility_outlined,
            onPressed: onView,
            tooltip: 'Xem',
          ),
        if (onEdit != null)
          AppIconButton(
            icon: Icons.edit_outlined,
            onPressed: onEdit,
            tooltip: 'Sửa',
          ),
        if (onDelete != null)
          AppIconButton(
            icon: Icons.delete_outline_rounded,
            onPressed: onDelete,
            color: const Color(0xFFEF4444),
            tooltip: 'Xoá',
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  INTERNAL: HOVER BUTTON
// ─────────────────────────────────────────────

class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color bgColor;
  final Color hoverColor;
  final Color borderColor;

  const _HoverButton({
    required this.child,
    required this.onPressed,
    required this.bgColor,
    required this.hoverColor,
    required this.borderColor,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHover ? widget.hoverColor : widget.bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.borderColor),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
