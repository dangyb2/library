import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  AppDropdownItem<T> — định nghĩa 1 lựa chọn trong dropdown
// ─────────────────────────────────────────────────────────────

class AppDropdownItem<T> {
  final T      value;
  final String label;
  /// Icon nhỏ bên trái label (tuỳ chọn)
  final IconData? icon;
  /// Dot màu bên trái (tuỳ chọn, ưu tiên hơn icon)
  final Color? dotColor;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.dotColor,
  });
}

// ─────────────────────────────────────────────────────────────
//  AppDropdown<T>
//
//  Dropdown dùng Overlay — nhất quán với phong cách FilterPopup
//  và _SearchSelectField đã có trong project.
//
//  Tính năng:
//   • Animate fade + slide khi mở/đóng
//   • Hover highlight trên từng item
//   • Hỗ trợ validator (FormField) — hiện error bên dưới
//   • Hỗ trợ dot color, icon trái, label, hint
//   • Close khi tap ngoài hoặc chọn item
//   • Con trỏ pointer khi hover
//   • Disabled state khi onChanged == null
//
//  Sử dụng cơ bản:
//    AppDropdown<BookCondition>(
//      label: 'Tình trạng sách *',
//      value: condition,
//      hint: 'Chọn tình trạng...',
//      items: [
//        AppDropdownItem(value: BookCondition.NEW,  label: 'Mới'),
//        AppDropdownItem(value: BookCondition.GOOD, label: 'Tốt'),
//      ],
//      onChanged: (v) => setState(() => condition = v),
//    )
//
//  Dùng trong Form (có validator):
//    AppDropdown<String?>(
//      label: 'Loại *',
//      value: _selected,
//      items: [...],
//      onChanged: (v) => setState(() => _selected = v),
//      validator: (v) => v == null ? 'Vui lòng chọn' : null,
//    )
// ─────────────────────────────────────────────────────────────

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint            = 'Chọn...',
    this.icon,
    this.validator,
    this.popupWidth,
    this.maxPopupHeight  = 280.0,
  });

  /// Danh sách lựa chọn
  final List<AppDropdownItem<T>> items;

  /// Giá trị đang chọn (null = chưa chọn)
  final T? value;

  /// Callback khi chọn item
  final ValueChanged<T>? onChanged;

  /// Label hiển thị phía trên ô (tuỳ chọn)
  final String? label;

  /// Placeholder khi chưa chọn
  final String hint;

  /// Icon phía trái ô (tuỳ chọn)
  final IconData? icon;

  /// Validator cho Form (tuỳ chọn)
  final String? Function(T?)? validator;

  /// Chiều rộng popup (mặc định = chiều rộng ô)
  final double? popupWidth;

  /// Chiều cao tối đa của popup
  final double maxPopupHeight;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();

  OverlayEntry?            _overlay;
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  // FormField error
  String? _error;

  static const _blue   = Color(0xFF2563EB);
  static const _blueBg = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.07),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Overlay helpers ─────────────────────────────────────────

  void _removeOverlay() { _overlay?.remove(); _overlay = null; }

  Future<void> _closeOverlay() async {
    await _ctrl.reverse();
    _removeOverlay();
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    if (_overlay != null) { _closeOverlay(); return; }

    final box       = _key.currentContext!.findRenderObject() as RenderBox;
    final pos       = box.localToGlobal(Offset.zero);
    final size      = box.size;
    final popWidth  = widget.popupWidth ?? size.width;

    _overlay = OverlayEntry(builder: (_) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeOverlay,
        child: Stack(children: [
          Positioned(
            left:  pos.dx,
            top:   pos.dy + size.height + 4,
            width: popWidth,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Material(
                  color: Colors.transparent,
                  child: _DropdownPopup<T>(
                    items:     widget.items,
                    selected:  widget.value,
                    maxHeight: widget.maxPopupHeight,
                    onSelect:  (item) {
                      widget.onChanged?.call(item.value);
                      // validate khi chọn
                      if (widget.validator != null) {
                        setState(() =>
                          _error = widget.validator!(item.value));
                      }
                      _closeOverlay();
                    },
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );

    Overlay.of(context).insert(_overlay!);
    _ctrl.forward(from: 0);
    setState(() {});
  }

  // ── Validate (gọi từ FormField nếu cần) ────────────────────

  String? _validate() {
    if (widget.validator == null) return null;
    final err = widget.validator!(widget.value);
    setState(() => _error = err);
    return err;
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Tìm item đang chọn
    AppDropdownItem<T>? selected;
    if (widget.value != null) {
      try {
        selected = widget.items.firstWhere(
            (i) => i.value == widget.value);
      } catch (_) {
        selected = null;
      }
    }

    final isOpen     = _overlay != null;
    final isDisabled = widget.onChanged == null;
    final hasError   = _error != null;
    final hasValue   = selected != null;

    // Nếu có validator → wrap trong FormField để hỗ trợ Form.validate()
    if (widget.validator != null) {
      return FormField<T>(
        validator: (_) => _validate(),
        builder: (field) => _buildContent(
          selected:   selected,
          isOpen:     isOpen,
          isDisabled: isDisabled,
          hasError:   field.hasError,
          errorText:  field.errorText,
          hasValue:   hasValue,
        ),
      );
    }

    return _buildContent(
      selected:   selected,
      isOpen:     isOpen,
      isDisabled: isDisabled,
      hasError:   hasError,
      errorText:  _error,
      hasValue:   hasValue,
    );
  }

  Widget _buildContent({
    required AppDropdownItem<T>? selected,
    required bool isOpen,
    required bool isDisabled,
    required bool hasError,
    required String? errorText,
    required bool hasValue,
  }) {
    final borderColor = hasError
        ? const Color(0xFFEF4444)
        : isOpen
            ? _blue
            : const Color(0xFFE5E7EB);

    final fillColor = isDisabled
        ? const Color(0xFFF3F4F6)
        : hasValue
            ? _blueBg
            : const Color(0xFFF9FAFB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        // ── Label ────────────────────────────────────────────
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // ── Trigger ──────────────────────────────────────────
        MouseRegion(
          cursor: isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: GestureDetector(
            key: _key,
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: isOpen || hasError ? 1.5 : 1,
                ),
                boxShadow: isOpen
                    ? [
                        BoxShadow(
                          color: _blue.withOpacity(0.10),
                          blurRadius: 0,
                          spreadRadius: 3,
                        )
                      ]
                    : null,
              ),
              child: Row(children: [

                // Leading icon hoặc dot
                if (selected?.dotColor != null) ...[
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: selected!.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (selected?.icon != null) ...[
                  Icon(selected!.icon, size: 15,
                      color: hasValue ? _blue : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 15,
                      color: hasValue ? _blue : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                ],

                // Label / hint
                Expanded(
                  child: Text(
                    hasValue ? selected!.label : widget.hint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.w400,
                      color: hasValue
                          ? const Color(0xFF111827)
                          : const Color(0xFFBFC4CC),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Arrow
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isOpen
                        ? _blue
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Error text ───────────────────────────────────────
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.error_outline_rounded,
                size: 13, color: Color(0xFFEF4444)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                errorText,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFEF4444)),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _DropdownPopup<T> — nội dung popup (list item)
// ─────────────────────────────────────────────────────────────

class _DropdownPopup<T> extends StatelessWidget {
  const _DropdownPopup({
    required this.items,
    required this.onSelect,
    required this.maxHeight,
    this.selected,
  });

  final List<AppDropdownItem<T>> items;
  final T?                       selected;
  final ValueChanged<AppDropdownItem<T>> onSelect;
  final double                   maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1, color: Color(0xFFF3F4F6),
            indent: 14, endIndent: 14,
          ),
          itemBuilder: (_, i) {
            final item       = items[i];
            final isSelected = item.value == selected;
            return _DropdownPopupItem<T>(
              item:       item,
              isSelected: isSelected,
              onTap:      () => onSelect(item),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _DropdownPopupItem<T> — 1 row trong popup (có hover)
// ─────────────────────────────────────────────────────────────

class _DropdownPopupItem<T> extends StatefulWidget {
  const _DropdownPopupItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppDropdownItem<T> item;
  final bool               isSelected;
  final VoidCallback        onTap;

  @override
  State<_DropdownPopupItem<T>> createState() =>
      _DropdownPopupItemState<T>();
}

class _DropdownPopupItemState<T>
    extends State<_DropdownPopupItem<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item       = widget.item;
    final isSelected = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : _hovered
                  ? const Color(0xFFF5F7FA)
                  : Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 11),
          child: Row(children: [

            // Dot hoặc icon
            if (item.dotColor != null) ...[
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: item.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
            ] else if (item.icon != null) ...[
              Icon(item.icon, size: 15,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF)),
              const SizedBox(width: 10),
            ],

            // Label
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF374151),
                ),
              ),
            ),

            // Checkmark
            if (isSelected)
              const Icon(Icons.check_rounded,
                  size: 15, color: Color(0xFF2563EB)),
          ]),
        ),
      ),
    );
  }
}