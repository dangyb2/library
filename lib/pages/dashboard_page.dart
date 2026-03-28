import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

// ─────────────────────────────────────────────────────────────
//  Palette
// ─────────────────────────────────────────────────────────────

class _C {
  static const indigo   = Color(0xFF6366F1);
  static const emerald  = Color(0xFF10B981);
  static const blue     = Color(0xFF3B82F6);
  static const red      = Color(0xFFEF4444);
  static const amber    = Color(0xFFF59E0B);
  static const gray800  = Color(0xFF1F2937);
  static const gray600  = Color(0xFF4B5563);
  static const gray500  = Color(0xFF6B7280);
  static const gray400  = Color(0xFF9CA3AF);
  static const gray200  = Color(0xFFE5E7EB);
  static const gray100  = Color(0xFFF3F4F6);
  static const gray50   = Color(0xFFF9FAFB);
  static const white    = Color(0xFFFFFFFF);

  static const pieColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];
}

// ─────────────────────────────────────────────────────────────
//  DashboardPage
// ─────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _service;

  DashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = DashboardService();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final stats = await _service.load();
    if (!mounted) return;
    setState(() {
      _stats     = stats;
      _isLoading = false;
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.gray50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_isLoading)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_stats == null || _stats!.allFailed)
              _buildAllError()
            else ...[
              _buildStatCards(),
              const SizedBox(height: 20),
              _buildChartsRow(),
              const SizedBox(height: 20),
              _buildBottomRow(),
              const SizedBox(height: 12),
              Text(
                'Cập nhật lúc ${DateFormat('HH:mm, dd/MM/yyyy').format(_stats!.loadedAt)}',
                style: const TextStyle(fontSize: 11, color: _C.gray400),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng Quan Thư Viện',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _C.gray800)),
            SizedBox(height: 3),
            Text('Chào mừng trở lại! Đây là tổng quan hôm nay.',
                style: TextStyle(fontSize: 13, color: _C.gray500)),
          ],
        ),
        const Spacer(),
        // Date chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.gray200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: _C.gray400),
              const SizedBox(width: 6),
              Text(today, style: const TextStyle(fontSize: 13, color: _C.gray600)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Refresh button
        _iconButton(
          icon: _isLoading ? null : Icons.refresh_rounded,
          onTap: _isLoading ? null : _load,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _iconButton({IconData? icon, VoidCallback? onTap, bool isLoading = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.gray200),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, size: 17, color: _C.gray500),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Stat cards
  // ─────────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    final b  = _stats!.books.data   ?? BookStats.empty();
    final r  = _stats!.readers.data ?? ReaderStats.empty();
    final bw = _stats!.borrows.data ?? BorrowStats.empty();

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth < 800 ? 2 : 4;
      return Wrap(spacing: 14, runSpacing: 14, children: [
        _statCard(
          icon: Icons.menu_book_rounded,
          title: 'Tổng Số Sách',
          value: b.totalCopies,
          sub: '${b.availableCopies} cuốn sẵn sàng',
          iconColor: _C.indigo,
          iconBg: const Color(0xFFEEF2FF),
          width: (c.maxWidth - (cols - 1) * 14) / cols,
        ),
        _statCard(
          icon: Icons.people_alt_rounded,
          title: 'Thành Viên',
          value: r.total,
          sub: '${r.active} đang hoạt động',
          iconColor: _C.emerald,
          iconBg: const Color(0xFFD1FAE5),
          width: (c.maxWidth - (cols - 1) * 14) / cols,
        ),
        _statCard(
          icon: Icons.swap_horiz_rounded,
          title: 'Đang Mượn',
          value: bw.active,
          sub: 'Lượt mượn hiện tại',
          iconColor: _C.blue,
          iconBg: const Color(0xFFDBEAFE),
          width: (c.maxWidth - (cols - 1) * 14) / cols,
        ),
        _statCard(
          icon: Icons.warning_amber_rounded,
          title: 'Quá Hạn',
          value: bw.overdue,
          sub: 'Cần xử lý ngay',
          iconColor: _C.red,
          iconBg: const Color(0xFFFEE2E2),
          width: (c.maxWidth - (cols - 1) * 14) / cols,
        ),
      ]);
    });
  }

  Widget _statCard({
    required IconData icon,
    required String   title,
    required int      value,
    required String   sub,
    required Color    iconColor,
    required Color    iconBg,
    required double   width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.gray100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: _C.gray500)),
                const SizedBox(height: 4),
                Text(
                  NumberFormat('#,###').format(value),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _C.gray800, height: 1),
                ),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 12, color: _C.gray400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Charts row: bar (2/3) + pie (1/3)
  // ─────────────────────────────────────────────────────────────

  Widget _buildChartsRow() {
    return LayoutBuilder(builder: (_, c) {
      final isWide = c.maxWidth >= 800;
      if (isWide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: _buildBarChart()),
          const SizedBox(width: 14),
          Expanded(flex: 1, child: _buildPieChart()),
        ]);
      }
      return Column(children: [
        _buildBarChart(),
        const SizedBox(height: 14),
        _buildPieChart(),
      ]);
    });
  }

  // ── Bar chart ─────────────────────────────────────────────────

  Widget _buildBarChart() {
    final monthly = _stats!.monthly.data ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lượt Mượn & Trả Sách',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.gray800)),
                  SizedBox(height: 2),
                  Text('7 tháng gần nhất',
                      style: TextStyle(fontSize: 12, color: _C.gray400)),
                ],
              ),
              const Spacer(),
              _legend(color: _C.indigo, label: 'Mượn'),
              const SizedBox(width: 14),
              _legend(color: _C.emerald, label: 'Trả'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: monthly.isEmpty
                ? const Center(child: Text('Không có dữ liệu', style: TextStyle(color: _C.gray400, fontSize: 13)))
                : CustomPaint(
                    size: Size.infinite,
                    painter: _BarChartPainter(data: monthly),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legend({required Color color, required String label}) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, color: _C.gray500)),
    ]);
  }

  // ── Pie chart ─────────────────────────────────────────────────

  Widget _buildPieChart() {
    final cats = _stats!.categories.data ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân Loại Sách',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.gray800)),
          const SizedBox(height: 2),
          const Text('Theo thể loại', style: TextStyle(fontSize: 12, color: _C.gray400)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: cats.isEmpty
                ? const Center(child: Text('Không có dữ liệu', style: TextStyle(color: _C.gray400, fontSize: 13)))
                : CustomPaint(
                    size: Size.infinite,
                    painter: _PieChartPainter(data: cats),
                  ),
          ),
          const SizedBox(height: 16),
          ...cats.take(4).toList().asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.value.name,
                              style: const TextStyle(fontSize: 12, color: _C.gray800),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('${e.value.percent.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.gray500)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value.percent / 100,
                        backgroundColor: _C.gray100,
                        valueColor: AlwaysStoppedAnimation(
                          _C.pieColors[e.key % _C.pieColors.length],
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Bottom row: recent activity + book status
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomRow() {
    return LayoutBuilder(builder: (_, c) {
      final isWide = c.maxWidth >= 800;
      if (isWide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildRecentActivity()),
          const SizedBox(width: 14),
          Expanded(child: _buildBookStatus()),
        ]);
      }
      return Column(children: [
        _buildRecentActivity(),
        const SizedBox(height: 14),
        _buildBookStatus(),
      ]);
    });
  }

  // ── Recent activity ───────────────────────────────────────────

  Widget _buildRecentActivity() {
    final activities = _stats!.recentActivity.data ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hoạt Động Gần Đây',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.gray800)),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Text('Không có hoạt động gần đây.',
                style: TextStyle(fontSize: 13, color: _C.gray400))
          else
            ...activities.asMap().entries.map((e) {
              final a = e.value;
              final isLast = e.key == activities.length - 1;
              return _activityRow(a, isLast: isLast);
            }),
        ],
      ),
    );
  }

  Widget _activityRow(RecentActivity a, {required bool isLast}) {
    final (bg, iconColor, badge, badgeBg, badgeText) = switch (a.status) {
      'returned' => (
          const Color(0xFFD1FAE5), _C.emerald,
          const Color(0xFFD1FAE5), const Color(0xFF065F46), 'Đã trả',
        ),
      'overdue' => (
          const Color(0xFFFEE2E2), _C.red,
          const Color(0xFFFEE2E2), const Color(0xFF991B1B), 'Quá hạn',
        ),
      _ => (
          const Color(0xFFDBEAFE), _C.blue,
          const Color(0xFFDBEAFE), const Color(0xFF1E40AF), 'Đang mượn',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _C.gray50)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.swap_horiz_rounded, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.readerName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _C.gray800),
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${a.status == 'returned' ? 'Trả' : 'Mượn'}: ${a.bookTitle}',
                  style: const TextStyle(fontSize: 12, color: _C.gray400),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: badge, borderRadius: BorderRadius.circular(20)),
            child: Text(badgeText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeBg)),
          ),
        ],
      ),
    );
  }

  // ── Book status ───────────────────────────────────────────────

  Widget _buildBookStatus() {
    final avail = _stats!.bookAvailability.data ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tình Trạng Sách',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.gray800)),
          const SizedBox(height: 16),
          if (avail.isEmpty)
            const Text('Không có dữ liệu.', style: TextStyle(fontSize: 13, color: _C.gray400))
          else
            ...avail.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _bookAvailabilityRow(b),
                )),
        ],
      ),
    );
  }

  Widget _bookAvailabilityRow(BookAvailability b) {
    final barColor = b.ratio == 0
        ? _C.red
        : b.ratio <= 0.3
            ? _C.amber
            : _C.emerald;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(b.title,
                  style: const TextStyle(fontSize: 13, color: _C.gray800),
                  overflow: TextOverflow.ellipsis),
            ),
            Text('${b.available}/${b.total}',
                style: const TextStyle(fontSize: 12, color: _C.gray500)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: b.ratio,
            backgroundColor: _C.gray100,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  All-error state
  // ─────────────────────────────────────────────────────────────

  Widget _buildAllError() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: _C.gray200),
          const SizedBox(height: 16),
          const Text('Không thể tải dữ liệu dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.gray800)),
          const SizedBox(height: 6),
          const Text('Kiểm tra kết nối mạng hoặc trạng thái máy chủ.',
              style: TextStyle(fontSize: 13, color: _C.gray400)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ]),
      ),
    );
  }

  // ── Shared card wrapper ───────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.gray100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Bar Chart Painter
// ─────────────────────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.data});
  final List<MonthlyBorrowStat> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const axisColor     = _C.gray200;
    const labelColor    = _C.gray400;
    const labelFontSize = 11.0;
    const bottomPad     = 26.0;
    const leftPad       = 36.0;
    const barGap        = 4.0;

    final chartH = size.height - bottomPad;
    final chartW = size.width  - leftPad;

    // Max value
    final maxVal = data
        .expand((d) => [d.borrowed, d.returned])
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();
    if (maxVal == 0) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chartH * (1 - i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      // Y labels
      _drawText(
        canvas,
        text: (maxVal * i / 4).round().toString(),
        x: leftPad - 6,
        y: y,
        color: labelColor,
        fontSize: labelFontSize,
        align: TextAlign.right,
      );
    }

    // Bars
    final groupW    = chartW / data.length;
    final barW      = (groupW - barGap * 3) / 2;
    final borrowPaint = Paint()..color = _C.indigo;
    final returnPaint = Paint()..color = _C.emerald;

    for (int i = 0; i < data.length; i++) {
      final d  = data[i];
      final x0 = leftPad + i * groupW + barGap;

      // Borrow bar
      final bH = (d.borrowed / maxVal) * chartH;
      final bRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x0, chartH - bH, barW, bH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(bRect, borrowPaint);

      // Return bar
      final rH = (d.returned / maxVal) * chartH;
      final rRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x0 + barW + barGap, chartH - rH, barW, rH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rRect, returnPaint);

      // X label
      _drawText(
        canvas,
        text: d.month,
        x: leftPad + i * groupW + groupW / 2,
        y: chartH + 8,
        color: labelColor,
        fontSize: labelFontSize,
        align: TextAlign.center,
      );
    }
  }

  void _drawText(
    Canvas canvas, {
    required String    text,
    required double    x,
    required double    y,
    required Color     color,
    required double    fontSize,
    TextAlign          align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
    )
      ..layout(maxWidth: 50);
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.data != data;
}

// ─────────────────────────────────────────────────────────────
//  Pie Chart Painter
// ─────────────────────────────────────────────────────────────

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.data});
  final List<CategoryStat> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final cx      = size.width  / 2;
    final cy      = size.height / 2;
    final radius  = math.min(cx, cy) * 0.92;
    const hole    = 0.62; // donut ratio

    double start = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweep  = 2 * math.pi * (data[i].percent / 100);
      final paint  = Paint()
        ..color      = _C.pieColors[i % _C.pieColors.length]
        ..style      = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        start,
        sweep - 0.025, // small gap
        true,
        paint,
      );

      // Punch donut hole
      final holePaint = Paint()
        ..color = _C.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius * hole, holePaint);

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_PieChartPainter old) => old.data != data;
}