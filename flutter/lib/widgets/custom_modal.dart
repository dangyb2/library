import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  AppModal  — dùng Dialog + Animation
// ─────────────────────────────────────────────────────────────

class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.controller,
    required this.header,
    required this.footer,
    required this.child,
    this.width = 680,
    this.maxHeightFactor = 0.88,
  });

  /// AnimationController do caller quản lý (vsync từ State của caller).
  final AnimationController controller;
  final AppModalHeader       header;
  final Widget               footer;
  final Widget               child;
  final double               width;
  final double               maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    final fade = CurvedAnimation(
        parent: controller, curve: Curves.easeOut);

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        alignment: Alignment.center,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 40, vertical: 32),
          child: Container(
            width: width,
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * maxHeightFactor,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 40,
                    offset: Offset(0, 16)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  Flexible(child: child),
                  footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AppModalHeader
// ─────────────────────────────────────────────────────────────

class AppModalHeader extends StatelessWidget {
  const AppModalHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.onClose,
    this.iconColor  = const Color(0xFF2563EB),
    this.iconBg     = const Color(0xFFEFF6FF),
    this.subtitle,
  });

  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String?  subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 20, 18),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),

          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Close button
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close_rounded,
                  size: 17, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AppModalFooter
// ─────────────────────────────────────────────────────────────

class AppModalFooter extends StatelessWidget {
  const AppModalFooter({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.confirmLabel    = 'Xác nhận',
    this.cancelLabel     = 'Huỷ',
    this.confirmIcon,
    this.isLoading       = false,
    this.loadingLabel    = 'Đang lưu...',
    this.showRequiredHint = true,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String    confirmLabel;
  final String    cancelLabel;
  final IconData? confirmIcon;
  final bool      isLoading;
  final String    loadingLabel;
  final bool      showRequiredHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: Row(
        children: [
          if (showRequiredHint)
            const Text('* Trường bắt buộc',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF))),
          const Spacer(),

          // Cancel — ẩn hoàn toàn khi cancelLabel rỗng
          if (cancelLabel.isNotEmpty) ...[
            _ModalButton(
              label:     cancelLabel,
              filled:    false,
              disabled:  isLoading,
              onPressed: isLoading ? null : onCancel,
            ),
            const SizedBox(width: 10),
          ],

          // Confirm
          _ModalButton(
            label:     isLoading ? loadingLabel : confirmLabel,
            icon:      isLoading ? null : confirmIcon,
            filled:    true,
            disabled:  isLoading,
            onPressed: isLoading ? null : onConfirm,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ModalButton — nội bộ
// ─────────────────────────────────────────────────────────────

class _ModalButton extends StatefulWidget {
  const _ModalButton({
    required this.label,
    required this.filled,
    this.icon,
    this.disabled  = false,
    this.onPressed,
  });

  final String        label;
  final bool          filled;
  final IconData?     icon;
  final bool          disabled;
  final VoidCallback? onPressed;

  @override
  State<_ModalButton> createState() => _ModalButtonState();
}

class _ModalButtonState extends State<_ModalButton> {
  bool _pressed = false;

  Color get _bg {
    if (widget.filled) {
      if (widget.disabled) return const Color(0xFFBFDBFE);
      return _pressed
          ? const Color(0xFF1D4ED8)
          : const Color(0xFF2563EB);
    }
    return _pressed ? const Color(0xFFF3F4F6) : Colors.white;
  }

  Color get _textColor {
    if (widget.filled) return Colors.white;
    return widget.disabled
        ? const Color(0xFFD1D5DB)
        : const Color(0xFF374151);
  }

  Color get _border {
    if (widget.filled) return Colors.transparent;
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 16, color: _textColor),
              const SizedBox(width: 6),
            ],
            Text(widget.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textColor)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AppModalDivider — đường kẻ nhẹ dùng trong body modal
// ─────────────────────────────────────────────────────────────

class AppModalDivider extends StatelessWidget {
  const AppModalDivider({super.key, this.vertical = 16});
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: const Divider(
          height: 1, thickness: 0.5, color: Color(0xFFF3F4F6)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AppModalField — TextFormField có label, dùng trong modal
// ─────────────────────────────────────────────────────────────

class AppModalField extends StatelessWidget {
  const AppModalField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines            = 1,
    this.keyboardType        = TextInputType.text,
    this.validator,
    this.readOnly            = false,
    this.onTap,
    this.suffixIcon,
  });

  final String                    label;
  final TextEditingController     controller;
  final String?                   hint;
  final int                       maxLines;
  final TextInputType             keyboardType;
  final String? Function(String?)? validator;
  final bool                      readOnly;
  /// Callback khi tap vào field (dùng cho date picker, v.v.)
  final VoidCallback?             onTap;
  /// Widget icon hiển thị ở cuối field
  final Widget?                   suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151))),
        if (label.isNotEmpty) const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          maxLines:     maxLines,
          keyboardType: keyboardType,
          validator:    validator,
          readOnly:     readOnly,
          onTap:        onTap,
          // Hiện con trỏ pointer khi là field bấm (readOnly + onTap)
          mouseCursor:  (readOnly && onTap != null)
              ? SystemMouseCursors.click
              : null,
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(
                fontSize: 13, color: Color(0xFFD1D5DB)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            filled:    true,
            fillColor: readOnly
                ? const Color(0xFFF3F4F6)
                : const Color(0xFFF9FAFB),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF2563EB), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFFEF4444), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}