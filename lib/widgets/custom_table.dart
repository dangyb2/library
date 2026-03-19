import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLUMN DEFINITION
// ─────────────────────────────────────────────

class AppTableColumn<T> {
  final String label;
  final int flex;
  final double? fixedWidth;
  final Widget Function(T row) builder;

  const AppTableColumn({
    required this.label,
    required this.builder,
    this.flex = 1,
    this.fixedWidth,
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

  const AppTable({
    super.key,
    required this.rows,
    required this.columns,
    this.emptyMessage = 'Không có dữ liệu',
    this.padding = const EdgeInsets.all(0),
  });

  @override
  State<AppTable<T>> createState() => _AppTableState<T>();
}

class _AppTableState<T> extends State<AppTable<T>> {
  // ✨ Track index row đang hover ở STATE của table, không phải từng row
  int _hoveredIndex = -1;

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
        // ✨ ClipRRect để border radius không bị overflow khi hover
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
          final cell = Text(
            col.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          );

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
    return Column(
      children: List.generate(widget.rows.length, (index) {
        final isFirst  = index == 0;
        final isLast   = index == widget.rows.length - 1;
        final isHover  = _hoveredIndex == index;

        // ✨ Border radius chỉ ở row đầu/cuối
        BorderRadius? radius;
        if (isFirst && isLast) {
          radius = const BorderRadius.vertical(bottom: Radius.circular(16));
        } else if (isLast) {
          radius = const BorderRadius.vertical(bottom: Radius.circular(16));
        }

        return Column(
          children: [
            // Divider trừ row đầu tiên
            if (!isFirst)
              const Divider(
                height: 1,
                color: Color(0xFFF3F4F6),
                indent: 20,
                endIndent: 20,
              ),

            // ✨ MouseRegion ở table level — set _hoveredIndex
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
                    final cell = col.builder(widget.rows[index]);
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