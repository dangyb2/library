import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

import '../models/notification_email.dart';
import '../services/notification_email_service.dart';
import '../widgets/custom_button.dart' hide TableActions;
import '../widgets/custom_filter.dart';
import '../widgets/custom_modal.dart';
import '../widgets/custom_table.dart';
import '../widgets/search_bar.dart';
import '../widgets/stat_card.dart';

// ─────────────────────────────────────────────
//  NotificationPage
// ─────────────────────────────────────────────

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  final NotificationService _service = NotificationService();
  final _dtFormat = DateFormat('dd/MM/yyyy HH:mm');

  // ── state ──────────────────────────────────
  List<NotificationSummaryView> _all      = [];
  List<NotificationSummaryView> _filtered = [];
  bool              _isLoading = true;
  String?           _error;
  String            _search       = '';
  String?           _statusFilter;
  String?           _typeFilter;
  bool              _isRetrying   = false;

  // ── modal animation ────────────────────────
  late AnimationController _modalCtrl;

  // ── stats ──────────────────────────────────
  int get _countTotal   => _all.length;
  int get _countSent    => _all.where((n) => n.status == NotificationStatus.SENT).length;
  int get _countFailed  => _all.where((n) => n.status == NotificationStatus.FAILED).length;
  int get _countPending => _all.where((n) => n.status == NotificationStatus.PENDING).length;

  List<String> get _searchSuggestions => {
        ..._all.map((n) => n.recipientEmail),
        ..._all.map((n) => n.subject),
      }.toList()..sort();

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

  // ── data ───────────────────────────────────

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _service.getAllNotifications();
    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _all = result.data ?? [];
        _applyFilter();
      } else {
        _error = result.errorMessage;
      }
    });
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    setState(() {
      _filtered = _all.where((n) {
        final matchSearch = q.isEmpty ||
            n.recipientEmail.toLowerCase().contains(q) ||
            n.subject.toLowerCase().contains(q) ||
            n.id.toLowerCase().contains(q);
        final matchStatus = _statusFilter == null ||
            n.status.value == _statusFilter;
        final matchType   = _typeFilter == null ||
            n.type.value == _typeFilter;
        return matchSearch && matchStatus && matchType;
      }).toList();
    });
  }

  // ── snackbar ───────────────────────────────

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: 13, color: Colors.white)),
      backgroundColor:
          error ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── modal helpers ──────────────────────────

  void _openModal(Widget Function(AnimationController) builder) {
    _modalCtrl.forward(from: 0);
    showDialog(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => builder(_modalCtrl),
    );
  }

  Future<void> _closeModal() async {
    await _modalCtrl.reverse();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // ── actions ────────────────────────────────

  Future<void> _openDetail(NotificationSummaryView row) async {
    final result = await _service.getNotificationById(row.id);
    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      _openModal((ctrl) => _NotificationDetailModal(
            controller: ctrl,
            detail: result.data!,
            onClose: _closeModal,
            onRetry: result.data!.status == NotificationStatus.FAILED
                ? () => _retryFromModal(result.data!)
                : null,
          ));
    } else {
      _toast(result.errorMessage ?? 'Không tải được chi tiết', error: true);
    }
  }

  Future<void> _retryRow(NotificationSummaryView row) async {
    setState(() => _isRetrying = true);
    final result = await _service.retry(row.id);
    if (!mounted) return;
    setState(() => _isRetrying = false);
    if (result.isSuccess) {
      await _loadData();
      _toast('Đã gửi lại thông báo thành công');
    } else {
      _toast(result.errorMessage ?? 'Gửi lại thất bại', error: true);
    }
  }

  Future<void> _retryFromModal(NotificationDetailView detail) async {
    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _isRetrying = true);
    final result = await _service.retry(detail.id);
    if (!mounted) return;
    setState(() => _isRetrying = false);
    if (result.isSuccess) {
      await _loadData();
      _toast('Đã gửi lại thông báo thành công');
    } else {
      _toast(result.errorMessage ?? 'Gửi lại thất bại', error: true);
    }
  }

  // ── table columns ──────────────────────────

  List<AppTableColumn<NotificationSummaryView>> get _columns => [
        AppTableColumn(
          label: 'Email nhận',
          flex: 3,
          sortable: true,
          sortKey: 'email',
          builder: (n) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                n.recipientEmail,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                n.subject,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AppTableColumn(
          label: 'Loại',
          flex: 3,
          builder: (n) => _TypeBadge(type: n.type),
        ),
        AppTableColumn(
          label: 'Trạng thái',
          flex: 2,
          sortable: true,
          sortKey: 'status',
          builder: (n) => _StatusBadge(status: n.status),
        ),

        AppTableColumn(
          label: 'Thời gian tạo',
          flex: 3,
          sortable: true,
          sortKey: 'createdAt',
          builder: (n) => Text(
            _dtFormat.format(n.createdAt.toLocal()),
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          label: 'Đã gửi lúc',
          flex: 3,
          sortable: true,
          sortKey: 'sentAt',
          builder: (n) => Text(
            n.sentAt != null ? _dtFormat.format(n.sentAt!.toLocal()) : '—',
            style: TextStyle(
              fontSize: 13,
              color: n.sentAt != null
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD1D5DB),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          label: 'Thao tác',
          fixedWidth: 100,
          builder: (n) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Xem chi tiết',
                child: _ActionIconBtn(
                  icon: Icons.visibility_outlined,
                  color: const Color(0xFF6B7280),
                  onTap: () => _openDetail(n),
                ),
              ),
              if (n.status == NotificationStatus.FAILED) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Gửi lại',
                  child: _ActionIconBtn(
                    icon: Icons.refresh_rounded,
                    color: const Color(0xFFDC2626),
                    onTap: _isRetrying ? null : () => _retryRow(n),
                  ),
                ),
              ],
            ],
          ),
        ),
      ];

  // ────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          AppButton(
            label: 'Thử lại',
            icon: Icons.refresh_rounded,
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────
          Row(children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông báo Email',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lịch sử gửi email thông báo đến độc giả',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: Icons.refresh_rounded,
              onPressed: _loadData,
              tooltip: 'Làm mới',
            ),
          ]),

          const SizedBox(height: 24),

          // ── Stat Cards ────────────────────────
          Row(children: [
            Expanded(child: StatCard(
              icon: Icons.notifications_outlined,
              title: 'Tổng thông báo',
              value: _countTotal,
              color: const Color(0xFF2563EB),
              subtitle: 'Tất cả thông báo',
            )),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              icon: Icons.check_circle_outline_rounded,
              title: 'Đã gửi',
              value: _countSent,
              color: const Color(0xFF16A34A),
              subtitle: 'Gửi thành công',
              onTap: () => setState(() {
                _statusFilter = _statusFilter == 'SENT' ? null : 'SENT';
                _applyFilter();
              }),
            )),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              icon: Icons.pending_outlined,
              title: 'Đang chờ',
              value: _countPending,
              color: const Color(0xFFF59E0B),
              subtitle: 'Chờ xử lý',
              onTap: () => setState(() {
                _statusFilter =
                    _statusFilter == 'PENDING' ? null : 'PENDING';
                _applyFilter();
              }),
            )),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              icon: Icons.error_outline_rounded,
              title: 'Thất bại',
              value: _countFailed,
              color: const Color(0xFFDC2626),
              subtitle: 'Cần gửi lại',
              onTap: () => setState(() {
                _statusFilter =
                    _statusFilter == 'FAILED' ? null : 'FAILED';
                _applyFilter();
              }),
            )),
          ]),

          const SizedBox(height: 24),

          // ── Toolbar ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: SearchBarWidget(
                  hintText: 'Tìm theo email, tiêu đề...',
                  suggestions: _searchSuggestions,
                  onChanged: (v) { _search = v; _applyFilter(); },
                  onSelect:  (v) { _search = v; _applyFilter(); },
                ),
              ),
              const SizedBox(width: 12),
              FilterPopup(
                label: 'Trạng thái',
                selected: _statusFilter,
                searchable: false,
                items: const {
                  'SENT':    'Đã gửi',
                  'PENDING': 'Đang chờ',
                  'FAILED':  'Thất bại',
                },
                onChanged: (v) =>
                    setState(() { _statusFilter = v; _applyFilter(); }),
              ),
              const SizedBox(width: 10),
              FilterPopup(
                label: 'Loại thông báo',
                selected: _typeFilter,
                searchable: true,
                items: {
                  for (final t in NotificationType.values) t.value: t.label
                },
                onChanged: (v) =>
                    setState(() { _typeFilter = v; _applyFilter(); }),
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: Icons.refresh_rounded,
                onPressed: _loadData,
                tooltip: 'Tải lại',
              ),
            ],
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              _filtered.isEmpty
                  ? 'Không tìm thấy kết quả'
                  : 'Hiển thị ${_filtered.length} / $_countTotal thông báo',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFD1D5DB)),
            ),
          ),

          // ── Table ─────────────────────────────
          AppTable<NotificationSummaryView>(
            rows: _filtered,
            columns: _columns,
            emptyMessage: _search.isNotEmpty
                ? 'Không tìm thấy thông báo phù hợp với "$_search"'
                : 'Chưa có thông báo nào',
            cellValue: (n, key) => switch (key) {
              'email'     => n.recipientEmail,
              'status'    => n.status.index,
              'createdAt' => n.createdAt,
              'sentAt'    => n.sentAt ?? DateTime(0),
              _           => '',
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _NotificationDetailModal
// ─────────────────────────────────────────────

class _NotificationDetailModal extends StatelessWidget {
  const _NotificationDetailModal({
    required this.controller,
    required this.detail,
    required this.onClose,
    this.onRetry,
  });

  final AnimationController  controller;
  final NotificationDetailView detail;
  final VoidCallback         onClose;
  final VoidCallback?        onRetry;

  static final _dtFmt = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return AppModal(
      controller: controller,
      width: 620,
      header: AppModalHeader(
        icon: Icons.email_outlined,
        title: 'Chi tiết thông báo',
        subtitle: detail.recipientEmail,
        iconColor: const Color(0xFF2563EB),
        iconBg: const Color(0xFFEFF6FF),
        onClose: onClose,
      ),
      footer: onRetry != null
          ? _RetryFooter(onClose: onClose, onRetry: onRetry!)
          : AppModalFooter(
              onCancel: onClose,
              onConfirm: onClose,
              confirmLabel: 'Đóng',
              cancelLabel: '',
              showRequiredHint: false,
            ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Meta row ─────────────────────────
            Row(children: [
              _TypeBadge(type: detail.type),
              const SizedBox(width: 10),
              _StatusBadge(status: detail.status),
              if (detail.retryCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.replay_rounded,
                        size: 11, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      'Thử lại: ${detail.retryCount} lần',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706)),
                    ),
                  ]),
                ),
              ],
            ]),

            const SizedBox(height: 16),

            // ── Info grid ─────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(children: [
                _InfoRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'ID',
                  value: detail.id,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.alternate_email_rounded,
                  label: 'Email nhận',
                  value: detail.recipientEmail,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Thời gian tạo',
                  value: _dtFmt.format(detail.createdAt.toLocal()),
                ),
                if (detail.sentAt != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.send_rounded,
                    label: 'Thời gian gửi',
                    value: _dtFmt.format(detail.sentAt!.toLocal()),
                    valueColor: const Color(0xFF16A34A),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 20),

            // ── Subject ───────────────────────────
            const Text(
              'Tiêu đề',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                detail.subject,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ───────────────────────────
            const Text(
              'Nội dung',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: detail.content.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        '(Không có nội dung)',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFFD1D5DB)),
                      ),
                    )
                  : Html(
                      data: detail.content,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.all(14),
                          fontSize: FontSize(13),
                          color: const Color(0xFF374151),
                          lineHeight: LineHeight(1.6),
                        ),
                        'a': Style(
                          color: const Color(0xFF2563EB),
                          textDecoration: TextDecoration.underline,
                        ),
                        'h1': Style(fontSize: FontSize(18), fontWeight: FontWeight.w700),
                        'h2': Style(fontSize: FontSize(16), fontWeight: FontWeight.w700),
                        'h3': Style(fontSize: FontSize(14), fontWeight: FontWeight.w600),
                        'p':  Style(margin: Margins.only(bottom: 8)),
                        'ul': Style(margin: Margins.only(left: 16, bottom: 8)),
                        'ol': Style(margin: Margins.only(left: 16, bottom: 8)),
                        'table': Style(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        'th': Style(
                          backgroundColor: const Color(0xFFF9FAFB),
                          padding: HtmlPaddings.symmetric(
                              horizontal: 12, vertical: 8),
                          fontWeight: FontWeight.w600,
                        ),
                        'td': Style(
                          padding: HtmlPaddings.symmetric(
                              horizontal: 12, vertical: 8),
                          border: Border(
                            top: BorderSide(color: const Color(0xFFE5E7EB)),
                          ),
                        ),
                      },
                    ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── _RetryFooter — footer đặc biệt khi có nút gửi lại ─────────

class _RetryFooter extends StatelessWidget {
  const _RetryFooter({
    required this.onClose,
    required this.onRetry,
  });

  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(children: [
        const Spacer(),
        AppButton(
          label: 'Đóng',
          variant: AppButtonVariant.secondary,
          onPressed: onClose,
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'Gửi lại',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.danger,
          onPressed: onRetry,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  _InfoRow — dòng thông tin trong modal
// ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  _TypeBadge — badge loại thông báo
// ─────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final NotificationType type;

  static const _configs = <NotificationType, (Color, Color)>{
    NotificationType.READER_CREATED:      (Color(0xFFEFF6FF), Color(0xFF2563EB)),
    NotificationType.READER_UPDATED:      (Color(0xFFEFF6FF), Color(0xFF2563EB)),
    NotificationType.READER_SUSPENDED:    (Color(0xFFFEF2F2), Color(0xFFDC2626)),
    NotificationType.READER_UNSUSPENDED:  (Color(0xFFF0FDF4), Color(0xFF16A34A)),
    NotificationType.MEMBERSHIP_EXPIRING: (Color(0xFFFEF3C7), Color(0xFFD97706)),
    NotificationType.MEMBERSHIP_EXPIRED:  (Color(0xFFFEF2F2), Color(0xFFDC2626)),
    NotificationType.BOOK_BORROWED:       (Color(0xFFEFF6FF), Color(0xFF2563EB)),
    NotificationType.BOOK_RETURNED:       (Color(0xFFF0FDF4), Color(0xFF16A34A)),
    NotificationType.BORROWING_EXTENDED:  (Color(0xFFF5F3FF), Color(0xFF7C3AED)),
    NotificationType.BOOK_DUE_SOON:       (Color(0xFFFEF3C7), Color(0xFFD97706)),
    NotificationType.BOOK_OVERDUE:        (Color(0xFFFEF2F2), Color(0xFFDC2626)),
    NotificationType.FINE_GENERATED:      (Color(0xFFFEF2F2), Color(0xFFDC2626)),
    NotificationType.PAYMENT:             (Color(0xFFF0FDF4), Color(0xFF16A34A)),
    NotificationType.LOST_BOOK_REPORT:    (Color(0xFFFFF7ED), Color(0xFFEA580C)),
    NotificationType.CANCEL_SUCCESS:      (Color(0xFFF9FAFB), Color(0xFF6B7280)),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _configs[type] ??
        (const Color(0xFFF3F4F6), const Color(0xFF6B7280));

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: text,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _StatusBadge — badge trạng thái gửi
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final NotificationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, text, icon) = switch (status) {
      NotificationStatus.SENT    => (
          'Đã gửi',
          const Color(0xFFF0FDF4),
          const Color(0xFF16A34A),
          Icons.check_circle_outline_rounded,
        ),
      NotificationStatus.PENDING => (
          'Đang chờ',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          Icons.schedule_rounded,
        ),
      NotificationStatus.FAILED  => (
          'Thất bại',
          const Color(0xFFFEF2F2),
          const Color(0xFFDC2626),
          Icons.error_outline_rounded,
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _ActionIconBtn — nút icon nhỏ có hover
// ─────────────────────────────────────────────

class _ActionIconBtn extends StatefulWidget {
  const _ActionIconBtn({
    required this.icon,
    required this.color,
    this.onTap,
  });
  final IconData     icon;
  final Color        color;
  final VoidCallback? onTap;

  @override
  State<_ActionIconBtn> createState() => _ActionIconBtnState();
}

class _ActionIconBtnState extends State<_ActionIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: _hovered && widget.onTap != null
                ? widget.color.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 16, color: widget.color),
        ),
      ),
    );
  }
}