import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/audit_log.dart';
import '../services/audit_log_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_filter.dart';
import '../widgets/custom_table.dart';
import '../widgets/search_bar.dart';
import '../widgets/stat_card.dart';

// ─────────────────────────────────────────────
//  AUDIT LOG PAGE
// ─────────────────────────────────────────────

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage>
    with TickerProviderStateMixin {
  final AuditLogService _service = AuditLogService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _dateOnlyFormat = DateFormat('dd/MM/yyyy');

  // ── State ───────────────────────────────────
  List<AuditLogSummaryView> _allLogs = [];
  List<AuditLogSummaryView> _filtered = [];
  AuditLogStats? _stats;
  bool _isLoading = true;
  String _search = '';
  String? _eventFilter; // lưu raw event type
  DateTime? _fromDate;
  DateTime? _toDate;

  // event types raw để populate filter
  List<String> _eventTypes = [];

  // ── Modal animation ─────────────────────────
  late AnimationController _modalCtrl;

  @override
  void initState() {
    super.initState();
    _modalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _loadData();
  }

  @override
  void dispose() {
    _modalCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final [logsResult, statsResult, typesResult] = await Future.wait([
      _service.listLogs(), // luôn fetch tất cả, lọc date client-side
      _service.getStats(),
      _service.listEventTypes(),
    ]);

    final logs =
        (logsResult as ServiceResult<List<AuditLogSummaryView>>).data ?? [];
    final stats = (statsResult as ServiceResult<AuditLogStats>).data;
    final types = (typesResult as ServiceResult<List<String>>).data ?? [];

    setState(() {
      _allLogs = logs;
      _stats = stats;
      _eventTypes = types;
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allLogs.where((log) {
        // Tìm kiếm tự do trên message, tên hiển thị của event type, aggregateId và id
        final matchSearch = _search.isEmpty ||
            log.message.toLowerCase().contains(_search.toLowerCase()) ||
            log.displayEventType.toLowerCase().contains(_search.toLowerCase()) ||
            log.aggregateId.toLowerCase().contains(_search.toLowerCase()) ||
            log.id.toLowerCase().contains(_search.toLowerCase());

        // Lọc theo loại sự kiện (so sánh raw)
        final matchEvent = _eventFilter == null || log.rawEventType == _eventFilter;

        // Lọc theo ngày
        final matchFrom = _fromDate == null || !log.occurredAt.isBefore(_fromDate!);
        final matchTo = _toDate == null || !log.occurredAt.isAfter(_toDate!);

        return matchSearch && matchEvent && matchFrom && matchTo;
      }).toList();
    });
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyFilter();
  }

  // ────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 24),
                    _buildStatCards(),
                    const SizedBox(height: 28),
                    _buildTableSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // ── PAGE HEADER ──────────────────────────────

  Widget _buildPageHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử hệ thống',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tổng ${_allLogs.length} sự kiện được ghi nhận',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  // ── STAT CARDS ───────────────────────────────

  Widget _buildStatCards() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.receipt_long_outlined,
            title: 'Tổng sự kiện',
            value: stats.total,
            color: const Color(0xFF2563EB),
            subtitle: 'sự kiện đã ghi',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.today_rounded,
            title: 'Hôm nay',
            value: stats.todayCount,
            color: const Color(0xFF7C3AED),
            subtitle: 'sự kiện trong ngày',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.date_range_outlined,
            title: '7 ngày qua',
            value: stats.weekCount,
            color: const Color(0xFF0891B2),
            subtitle: 'sự kiện tuần này',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.filter_list_rounded,
            title: 'Đang hiển thị',
            value: _filtered.length,
            color: const Color(0xFF16A34A),
            subtitle: 'kết quả lọc hiện tại',
          ),
        ),
      ],
    );
  }

  // ── TABLE SECTION ────────────────────────────

  Widget _buildTableSection() {
    final eventTypeMap = <String, String>{};
    for (final raw in _eventTypes) {
      try {
        eventTypeMap[raw] = AuditEventTypeName.fromString(raw).viName;
      } catch (_) {
        eventTypeMap[raw] = raw; // fallback
      }
    }
    return Column(
      children: [
        // Toolbar
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SearchBarWidget(
                hintText: 'Tìm theo nội dung, loại sự kiện, id...',
                suggestions: [
                  ..._allLogs.map((l) => l.displayEventType),
                  ..._allLogs.map((l) => l.aggregateId),
                ],
                onChanged: (v) {
                  _search = v;
                  _applyFilter();
                },
                onSelect: (v) {
                  _search = v;
                  _applyFilter();
                },
              ),
            ),
            const SizedBox(width: 12),
            FilterPopup(
              label: 'Loại sự kiện',
              icon: Icons.category_outlined,
              selected: _eventFilter,
              searchable: _eventTypes.length > 6,
              items: eventTypeMap,
              onChanged: (v) {
                setState(() => _eventFilter = v);
                _applyFilter();
              },
            ),
            const SizedBox(width: 8),
            _DateRangeButton(
              from: _fromDate,
              to: _toDate,
              dateFormat: _dateOnlyFormat,
              onApply: (from, to) {
                setState(() {
                  _fromDate = from;
                  _toDate = to;
                });
                _applyFilter();
              },
              onClear: _clearDateRange,
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: Icons.refresh_rounded,
              onPressed: () {
                _service.invalidateCache();
                _loadData();
              },
              tooltip: 'Làm mới',
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTable<AuditLogSummaryView>(
          rows: _filtered,
          emptyMessage: 'Không có sự kiện nào',
          columns: [
            // Event Type
            AppTableColumn(
              label: 'Loại sự kiện',
              flex: 2,
              builder: (row) => Align(
                alignment: Alignment.centerLeft,
                child: _EventTypeBadge(
                  rawEventType: row.rawEventType,
                  displayName: row.displayEventType,
                ),
              ),
            ),
            // Message
            AppTableColumn(
              label: 'Nội dung',
              flex: 4,
              builder: (row) => Text(
                row.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Occurred At
            AppTableColumn(
              label: 'Thời gian',
              flex: 2,
              builder: (row) => Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: Color(0xFFD1D5DB)),
                  const SizedBox(width: 5),
                  Text(
                    _dateFormat.format(row.occurredAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  _DateRangeButton — dropdown popup chọn ngày
//  với preset nhanh + 2 ô từ/đến
// ─────────────────────────────────────────────

class _DateRangeButton extends StatefulWidget {
  const _DateRangeButton({
    required this.onApply,
    required this.onClear,
    required this.dateFormat,
    this.from,
    this.to,
  });

  final DateTime? from;
  final DateTime? to;
  final DateFormat dateFormat;
  final void Function(DateTime, DateTime) onApply;
  final VoidCallback onClear;

  @override
  State<_DateRangeButton> createState() => _DateRangeButtonState();
}

class _DateRangeButtonState extends State<_DateRangeButton>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  OverlayEntry? _overlay;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool _hovered = false;
  bool _pickerOpen = false; // true khi showDatePicker đang mở

  // ── scroll listener ────────────────────────
  ScrollPosition? _scrollPosition;

  static const _blue = Color(0xFF2563EB);
  static const _blueBg = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScroll);
  }

  void _onScroll() {
    if (_overlay != null && !_pickerOpen) _removeOverlay();
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Future<void> _closeOverlay() async {
    await _ctrl.reverse();
    _removeOverlay();
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_overlay != null) {
      _closeOverlay();
      return;
    }

    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(builder: (overlayCtx) {
      final popupRight =
          MediaQuery.sizeOf(context).width - (pos.dx + size.width);
      final popupTop = pos.dy + size.height + 6;

      return Stack(children: [
        // Barrier trong suốt — chỉ đóng khi tap bên NGOÀI popup
        // và khi KHÔNG có date picker dialog đang mở
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (!_pickerOpen) _closeOverlay();
            },
          ),
        ),
        // Popup — bọc GestureDetector để hấp thụ tap, tránh bubble lên barrier
        Positioned(
          right: popupRight,
          top: popupTop,
          width: 300,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // hấp thụ tap trong popup
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Material(
                  color: Colors.transparent,
                  child: _DateRangePopup(
                    initialFrom: widget.from,
                    initialTo: widget.to,
                    dateFormat: widget.dateFormat,
                    onPickerOpen: () => _pickerOpen = true,
                    onPickerClose: () => _pickerOpen = false,
                    onApply: (from, to) {
                      widget.onApply(from, to);
                      _closeOverlay();
                    },
                    onClear: () {
                      widget.onClear();
                      _closeOverlay();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    });

    Overlay.of(context).insert(_overlay!);
    _ctrl.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _overlay != null;
    final isActive = widget.from != null && widget.to != null;
    final label = isActive
        ? '${widget.dateFormat.format(widget.from!)}  –  ${widget.dateFormat.format(widget.to!)}'
        : 'Lọc theo ngày';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: _key,
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive || isOpen
                ? _blueBg
                : _hovered
                    ? const Color(0xFFF9FAFB)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive || isOpen ? _blue : const Color(0xFFE5E7EB),
              width: isActive || isOpen ? 1.5 : 1,
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
              Icon(Icons.date_range_rounded, size: 15,
                  color: isActive || isOpen ? _blue : const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive || isOpen ? _blue : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 6),
              if (isActive)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _removeOverlay();
                    if (mounted) setState(() {});
                    widget.onClear();
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: _blue, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 10, color: Colors.white),
                  ),
                )
              else
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isOpen ? _blue : const Color(0xFF9CA3AF)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _DateRangePopup — nội dung popup chọn ngày
// ─────────────────────────────────────────────

class _DateRangePopup extends StatefulWidget {
  const _DateRangePopup({
    required this.onApply,
    required this.onClear,
    required this.dateFormat,
    required this.onPickerOpen,
    required this.onPickerClose,
    this.initialFrom,
    this.initialTo,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;
  final DateFormat dateFormat;
  final void Function(DateTime, DateTime) onApply;
  final VoidCallback onClear;
  final VoidCallback onPickerOpen;
  final VoidCallback onPickerClose;

  @override
  State<_DateRangePopup> createState() => _DateRangePopupState();
}

class _DateRangePopupState extends State<_DateRangePopup> {
  late DateTime? _from;
  late DateTime? _to;
  int? _activePreset;

  static const _blue = Color(0xFF2563EB);
  static const _presets = [
    ('Hôm nay', 0),
    ('7 ngày qua', 7),
    ('30 ngày qua', 30),
    ('Tháng này', -1),
  ];

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  void _applyPreset(int index) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime from;
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (index == 0) {
      from = today;
    } else if (index == 3) {
      from = DateTime(now.year, now.month, 1);
    } else {
      final days = _presets[index].$2;
      from = today.subtract(Duration(days: days));
    }

    setState(() {
      _from = from;
      _to = to;
      _activePreset = index;
    });
  }

  bool get _canApply => _from != null && _to != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 14, color: _blue),
                const SizedBox(width: 8),
                const Text('Chọn khoảng thời gian',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    )),
              ]),
            ),
            // ── Preset chips ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_presets.length, (i) {
                  final isActive = _activePreset == i;
                  return GestureDetector(
                    onTap: () => _applyPreset(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? _blue : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _presets[i].$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // ── Divider ───────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            // ── Từ / Đến ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Expanded(
                  child: _DateField(
                    label: 'Từ ngày',
                    value: _from,
                    lastDate: _to ?? DateTime.now(),
                    onPickerOpen: widget.onPickerOpen,
                    onPickerClose: widget.onPickerClose,
                    onPicked: (d) => setState(() {
                      _from = d;
                      _activePreset = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('–',
                    style: TextStyle(
                        color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: 'Đến ngày',
                    value: _to,
                    firstDate: _from ?? DateTime(2020),
                    onPickerOpen: widget.onPickerOpen,
                    onPickerClose: widget.onPickerClose,
                    onPicked: (d) => setState(() {
                      _to = DateTime(d.year, d.month, d.day, 23, 59, 59);
                      _activePreset = null;
                    }),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // ── Actions ───────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(children: [
                // Xoá
                GestureDetector(
                  onTap: widget.onClear,
                  child: const Text('Xoá bộ lọc',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      )),
                ),
                const Spacer(),
                // Áp dụng
                GestureDetector(
                  onTap: _canApply ? () => widget.onApply(_from!, _to!) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _canApply ? _blue : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Áp dụng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _canApply
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                        )),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _DateField — ô chọn 1 ngày trong popup
// ─────────────────────────────────────────────

class _DateField extends StatefulWidget {
  const _DateField({
    required this.label,
    required this.onPicked,
    required this.onPickerOpen,
    required this.onPickerClose,
    this.value,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onPickerOpen;
  final VoidCallback onPickerClose;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  bool _hovered = false;
  static const _fmt = 'dd/MM/yy';

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final label = hasValue
        ? DateFormat(_fmt).format(widget.value!)
        : widget.label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          widget.onPickerOpen();
          final picked = await showDatePicker(
            context: context,
            initialDate: widget.value ?? DateTime.now(),
            firstDate: widget.firstDate ?? DateTime(2020),
            lastDate: widget.lastDate ?? DateTime.now(),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF2563EB),
                ),
              ),
              child: child!,
            ),
          );
          widget.onPickerClose();
          if (picked != null) widget.onPicked(picked);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFF5F7FA)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue
                  ? const Color(0xFF2563EB).withOpacity(0.4)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_rounded,
                size: 13,
                color: hasValue
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFD1D5DB),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? const Color(0xFF111827)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _EventTypeBadge — chip màu theo event type
// ─────────────────────────────────────────────

class _EventTypeBadge extends StatelessWidget {
  const _EventTypeBadge({
    required this.rawEventType,
    required this.displayName,
  });
  final String rawEventType;
  final String displayName;

  static Color _colorFor(String rawType) {
    final t = rawType.toUpperCase();
    if (t.contains('CREATE') || t.contains('ADD')) return const Color(0xFF16A34A);
    if (t.contains('UPDATE') || t.contains('EDIT')) return const Color(0xFF2563EB);
    if (t.contains('DELETE') || t.contains('REMOVE')) return const Color(0xFFDC2626);
    if (t.contains('BORROW')) return const Color(0xFF7C3AED);
    if (t.contains('RETURN')) return const Color(0xFF0891B2);
    if (t.contains('EXTEND')) return const Color(0xFFD97706);
    if (t.contains('LOST')) return const Color(0xFFEA580C);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(rawEventType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}