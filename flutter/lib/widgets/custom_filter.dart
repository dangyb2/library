import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  FilterChipItem — định nghĩa 1 chip
// ─────────────────────────────────────────────────────────────

class FilterChipItem<T> {
  final T? value;          // null = "Tất cả"
  final String label;
  final Color? dotColor;   // null = không hiện dot
  final Color activeBg;
  final Color activeText;

  const FilterChipItem({
    required this.value,
    required this.label,
    this.dotColor,
    this.activeBg = const Color(0xFF111827),
    this.activeText = Colors.white,
  });
}

// ─────────────────────────────────────────────────────────────
//  FilterChips — dãy pill chips nằm ngang
//
//  Dùng khi:  filter có ít lựa chọn cố định (≤6), hiển thị
//             toàn bộ cùng lúc (không cần popup).
//
//  Ví dụ: Trạng thái mượn (Tất cả / Đang mượn / Quá hạn / ...)
//
//  Usage:
//    FilterChips<BorrowStatus>(
//      chips: [...],
//      selected: _statusFilter,
//      onChanged: (v) => setState(() => _statusFilter = v),
//    )
// ─────────────────────────────────────────────────────────────

class FilterChips<T> extends StatelessWidget {
  final List<FilterChipItem<T>> chips;
  final T? selected;
  final ValueChanged<T?> onChanged;

  const FilterChips({
    super.key,
    required this.chips,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) => _FilterChipTile<T>(
        item: c,
        isActive: selected == c.value,
        onTap: () => onChanged(c.value),
      )).toList(),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────

class _FilterChipTile<T> extends StatefulWidget {
  final FilterChipItem<T> item;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChipTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterChipTile<T>> createState() => _FilterChipTileState<T>();
}

class _FilterChipTileState<T> extends State<_FilterChipTile<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item     = widget.item;
    final isActive = widget.isActive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isActive
                ? item.activeBg
                : _hovered
                    ? const Color(0xFFF3F4F6)
                    : item.dotColor != null
                        ? item.dotColor!.withOpacity(0.08)
                        : const Color(0xFFF3F4F6),
            border: Border.all(
              color: isActive ? Colors.transparent : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Check khi active
              if (isActive && item.value != null) ...[
                Icon(Icons.check_rounded, size: 13, color: item.activeText),
                const SizedBox(width: 5),
              ]
              // Dot khi không active
              else if (!isActive && item.dotColor != null) ...[
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: item.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? item.activeText
                      : item.dotColor ?? const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FilterPopup — nút bấm mở dropdown có thể tìm kiếm
//
//  Dùng khi:  filter có nhiều lựa chọn (genre, năm, ...) hoặc
//             cần tìm kiếm trong danh sách.
//
//  Ví dụ: Thể loại sách (30+ lựa chọn, có search)
//         Trạng thái kho (3 lựa chọn, không search)
//
//  Usage:
//    FilterPopup(
//      label: 'Thể loại',
//      items: BookGenres.all,       // Map<String, String>
//      selected: _activeGenre,
//      searchable: true,
//      onChanged: _onGenreFilter,
//    )
// ─────────────────────────────────────────────────────────────

class FilterPopup extends StatefulWidget {
  const FilterPopup({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.selected,
    this.searchable = false,
    this.icon,
    this.dotColors,        // key → dot color, optional
  });

  final String                label;
  final Map<String, String>   items;
  final String?               selected;
  final bool                  searchable;
  final IconData?             icon;
  final Map<String, Color>?   dotColors;
  final ValueChanged<String?> onChanged;

  @override
  State<FilterPopup> createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup>
    with SingleTickerProviderStateMixin {
  OverlayEntry?            _overlay;
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;
  final _key = GlobalKey();

  static const _blue   = Color(0xFF2563EB);
  static const _blueBg = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _removeOverlay() { _overlay?.remove(); _overlay = null; }

  Future<void> _closeOverlay() async {
    await _ctrl.reverse();
    _removeOverlay();
  }

  void _toggle() {
    if (_overlay != null) { _closeOverlay(); return; }

    final box        = _key.currentContext!.findRenderObject() as RenderBox;
    final pos        = box.localToGlobal(Offset.zero);
    final size       = box.size;
    final popupWidth = widget.searchable ? 260.0 : 200.0;

    _overlay = OverlayEntry(builder: (_) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _closeOverlay,
      child: Stack(children: [
        Positioned(
          left:  pos.dx + size.width - popupWidth,
          top:   pos.dy + size.height + 6,
          width: popupWidth,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: _FilterPopupContent(
                  items:      widget.items,
                  selected:   widget.selected,
                  searchable: widget.searchable,
                  dotColors:  widget.dotColors,
                  onSelect: (val) {
                    widget.onChanged(val);
                    _closeOverlay();
                  },
                ),
              ),
            ),
          ),
        ),
      ]),
    ));

    Overlay.of(context).insert(_overlay!);
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isActive     = widget.selected != null;
    final displayLabel = isActive
        ? (widget.items[widget.selected] ?? widget.label)
        : widget.label;

    return GestureDetector(
      key: _key,
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? _blueBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? _blue : const Color(0xFFE5E7EB),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 15,
                  color: isActive ? _blue : const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
            ],
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? _blue : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: _overlay != null ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isActive ? _blue : const Color(0xFF9CA3AF)),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  _removeOverlay();
                  widget.onChanged(null);
                },
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: _blue, shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      size: 10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── _FilterPopupContent ───────────────────────────────────────

class _FilterPopupContent extends StatefulWidget {
  const _FilterPopupContent({
    required this.items,
    required this.onSelect,
    required this.searchable,
    this.selected,
    this.dotColors,
  });

  final Map<String, String>   items;
  final String?               selected;
  final bool                  searchable;
  final Map<String, Color>?   dotColors;
  final ValueChanged<String?> onSelect;

  @override
  State<_FilterPopupContent> createState() => _FilterPopupContentState();
}

class _FilterPopupContentState extends State<_FilterPopupContent> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.items.entries.toList()
        : widget.items.entries
            .where((e) =>
                e.value.toLowerCase().contains(_query.toLowerCase()) ||
                e.key.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 340),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Search box ──────────────────────────
            if (widget.searchable)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF374151)),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFFBFC4CC)),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(Icons.search_rounded,
                          size: 16, color: Color(0xFF9CA3AF)),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),

            // ── "Tất cả" row ────────────────────────
            _PopupItem(
              label: 'Tất cả',
              isSelected: widget.selected == null,
              onTap: () => widget.onSelect(null),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

            // ── Item list ───────────────────────────
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final e = filtered[i];
                  return _PopupItem(
                    label: e.value,
                    isSelected: widget.selected == e.key,
                    dotColor: widget.dotColors?[e.key],
                    onTap: () => widget.onSelect(e.key),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  const _PopupItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  final String       label;
  final bool         isSelected;
  final Color?       dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFF5F7FA),
        splashColor: Colors.transparent,
        highlightColor: const Color(0xFFEEF0F3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            // Dot
            if (dotColor != null) ...[
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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