import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLUMN DEFINITION
// ─────────────────────────────────────────────

class AppTableColumn<T> {
  final String label;
  final int flex;
  final double? fixedWidth;
  final Widget Function(T row) builder;

  /// Nếu true, header cột này có thể bấm để sắp xếp.
  /// [sortKey] là key dùng để so sánh — nếu null thì dùng [label].
  final bool sortable;
  final String? sortKey;

  const AppTableColumn({
    required this.label,
    required this.builder,
    this.flex = 1,
    this.fixedWidth,
    this.sortable  = false,
    this.sortKey,
  });
}

// ─────────────────────────────────────────────
//  APP TABLE
// ─────────────────────────────────────────────

class AppTable<T> extends StatefulWidget {
  final List<T> rows;
  final List<AppTableColumn<T>> columns;
  final String? emptyMessage;
  final EdgeInsets padding;

  /// Optional: external comparator dùng khi cột sortable được bấm.
  /// Nhận (row, sortKey) → Comparable để so sánh.
  /// Nếu null, sort sẽ không hoạt động dù [sortable] = true.
  final Comparable Function(T row, String sortKey)? cellValue;

  const AppTable({
    super.key,
    required this.rows,
    required this.columns,
    this.emptyMessage = 'Không có dữ liệu',
    this.padding = const EdgeInsets.all(0),
    this.cellValue,
  });

  @override
  State<AppTable<T>> createState() => _AppTableState<T>();
}

class _AppTableState<T> extends State<AppTable<T>> {
  int  _hoveredIndex = -1;
  String? _sortKey;
  bool    _sortAsc = true;

  List<T> get _sortedRows {
    if (_sortKey == null || widget.cellValue == null) return widget.rows;
    final list = List<T>.from(widget.rows);
    list.sort((a, b) {
      final va = widget.cellValue!(a, _sortKey!);
      final vb = widget.cellValue!(b, _sortKey!);
      final cmp = va.compareTo(vb);
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _onHeaderTap(AppTableColumn<T> col) {
    if (!col.sortable || widget.cellValue == null) return;
    final key = col.sortKey ?? col.label;
    setState(() {
      if (_sortKey == key) {
        _sortAsc = !_sortAsc;
      } else {
        _sortKey = key;
        _sortAsc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildHeader(),
              widget.rows.isEmpty
                  ? _buildEmpty()
                  : _buildRows(),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: const Color(0xFFF9FAFB),
      child: Row(
        children: widget.columns.map((col) {
          final key      = col.sortKey ?? col.label;
          final isActive = col.sortable && _sortKey == key;
          final canSort  = col.sortable && widget.cellValue != null;

          Widget cell = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                col.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              if (canSort) ...[
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    isActive
                        ? (_sortAsc
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded)
                        : Icons.unfold_more_rounded,
                    key: ValueKey('$key-$isActive-$_sortAsc'),
                    size: 13,
                    color: isActive
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ],
          );

          if (canSort) {
            cell = MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _onHeaderTap(col),
                child: cell,
              ),
            );
          }

          if (col.fixedWidth != null) {
            return SizedBox(width: col.fixedWidth, child: cell);
          }
          return Expanded(flex: col.flex, child: cell);
        }).toList(),
      ),
    );
  }

  // ── ROWS ──────────────────────────────────────────────────────

  Widget _buildRows() {
    final rows = _sortedRows;
    return Column(
      children: List.generate(rows.length, (index) {
        final isFirst  = index == 0;
        final isLast   = index == rows.length - 1;
        final isHover  = _hoveredIndex == index;

        BorderRadius? radius;
        if (isFirst && isLast) {
          radius = const BorderRadius.vertical(bottom: Radius.circular(16));
        } else if (isLast) {
          radius = const BorderRadius.vertical(bottom: Radius.circular(16));
        }

        return Column(
          children: [
            if (!isFirst)
              const Divider(
                height: 1,
                color: Color(0xFFF3F4F6),
                indent: 20,
                endIndent: 20,
              ),
            MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit:  (_) => setState(() => _hoveredIndex = -1),
              child: Container(
                decoration: BoxDecoration(
                  color: isHover ? const Color(0xFFF5F5F5) : Colors.transparent,
                  borderRadius: radius,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: widget.columns.map((col) {
                    final cell = col.builder(rows[index]);
                    if (col.fixedWidth != null) {
                      return SizedBox(width: col.fixedWidth, child: cell);
                    }
                    return Expanded(flex: col.flex, child: cell);
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── EMPTY ─────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                size: 36, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 10),
            Text(
              widget.emptyMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────
//  TABLE ACTIONS
//  Nút thao tác cuối mỗi row: xem / sửa / kho / xoá
// ─────────────────────────────────────────────

class TableActions extends StatelessWidget {
  const TableActions({
    super.key,
    this.onView,
    this.onEdit,
    this.onStock,
    this.onDelete,
  });

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onStock;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onView != null)
          _ActionBtn(
            icon:    Icons.visibility_outlined,
            color:   const Color(0xFF6B7280),
            tooltip: 'Xem chi tiết',
            onTap:   onView!,
          ),
        if (onEdit != null) ...[
          const SizedBox(width: 4),
          _ActionBtn(
            icon:    Icons.edit_outlined,
            color:   const Color(0xFF2563EB),
            tooltip: 'Chỉnh sửa',
            onTap:   onEdit!,
          ),
        ],
        if (onStock != null) ...[
          const SizedBox(width: 4),
          _ActionBtn(
            icon:    Icons.inventory_2_outlined,
            color:   const Color(0xFF7C3AED),
            tooltip: 'Cập nhật kho',
            onTap:   onStock!,
          ),
        ],
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          _ActionBtn(
            icon:    Icons.delete_outline_rounded,
            color:   const Color(0xFFEF4444),
            tooltip: 'Xoá',
            onTap:   onDelete!,
          ),
        ],
      ],
    );
  }
}

// ── _ActionBtn — nút icon nhỏ có hover + tooltip ──────────────

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color    color;
  final String   tooltip;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 16, color: widget.color),
          ),
        ),
      ),
    );
  }
}