import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reader.dart';
import '../services/reader_service.dart';
import '../widgets/custom_button.dart' hide TableActions;
import '../widgets/custom_filter.dart';
import '../widgets/custom_modal.dart';
import '../widgets/custom_table.dart';
import '../widgets/search_bar.dart';
import '../widgets/stat_card.dart';

// ─────────────────────────────────────────────────────────────
//  ReadersPage
// ─────────────────────────────────────────────────────────────

class ReadersPage extends StatefulWidget {
  const ReadersPage({super.key});

  @override
  State<ReadersPage> createState() => _ReadersPageState();
}

class _ReadersPageState extends State<ReadersPage> {
  late final ReaderService _service;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // ── State ──────────────────────────────────────────────────────
  List<ReaderView> _readers  = [];
  List<ReaderView> _filtered = [];
  bool    _isLoading   = true;
  String? _error;
  String  _searchText  = '';
  String? _statusFilter; // 'NORMAL' | 'SUSPENDED' | 'expired'

  // ── Stats ──────────────────────────────────────────────────────
  int get _total     => _readers.length;
  int get _normal    => _readers.where((r) =>
      r.status == ReaderStatus.NORMAL && !r.isMembershipExpired).length;
  int get _suspended => _readers.where((r) =>
      r.status == ReaderStatus.SUSPENDED).length;
  int get _expired   => _readers.where((r) =>
      r.isMembershipExpired && r.status == ReaderStatus.NORMAL).length;

  List<String> get _searchSuggestions => {
        ..._readers.map((r) => r.name),
        ..._readers.map((r) => r.email),
      }.toList()..sort();

  @override
  void initState() {
    super.initState();
    _service = ReaderService();
    _loadReaders();
  }

  // ─────────────────────────────────────────────────────────────
  //  Data
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadReaders() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _service.findAll();
    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _readers = result.data ?? [];
        _applyFilter();
      } else {
        _error = result.errorMessage;
      }
    });
  }

  void _applyFilter() {
    final q = _searchText.toLowerCase();
    _filtered = _readers.where((r) {
      final matchSearch = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          r.email.toLowerCase().contains(q) ||
          r.phone.toLowerCase().contains(q) ||
          r.id.toLowerCase().contains(q);
      final matchStatus = switch (_statusFilter) {
        'NORMAL'    => r.status == ReaderStatus.NORMAL && !r.isMembershipExpired,
        'SUSPENDED' => r.status == ReaderStatus.SUSPENDED,
        'expired'   => r.isMembershipExpired && r.status == ReaderStatus.NORMAL,
        _           => true,
      };
      return matchSearch && matchStatus;
    }).toList();
  }

  void _onSearch(String v) => setState(() { _searchText = v; _applyFilter(); });

  void _onStatusFilter(String? s) => setState(() {
    _statusFilter = (_statusFilter == s) ? null : s;
    _applyFilter();
  });

  // ─────────────────────────────────────────────────────────────
  //  Snackbar
  // ─────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────────────────────

  Future<void> _openCreate() async {
    final created = await showDialog<ReaderView>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => _AddReaderModal(service: _service),
    );
    if (created == null || !mounted) return;
    await _loadReaders();
    _showSnackBar('Đã thêm độc giả "${created.name}"', isError: false);
  }

  Future<void> _openDetail(ReaderView reader) async {
    final result = await _service.findById(reader.id);
    if (!mounted) return;
    if (result.isSuccess) {
      await showDialog<void>(
        context: context,
        barrierColor: const Color(0x80000000),
        builder: (_) => _ReaderDetailModal(reader: result.data!),
      );
    } else {
      _showSnackBar(
          result.errorMessage ?? 'Không tải được chi tiết', isError: true);
    }
  }

  Future<void> _openEdit(ReaderView reader) async {
    final updated = await showDialog<ReaderView>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => _EditReaderModal(service: _service, reader: reader),
    );
    if (updated == null || !mounted) return;
    await _loadReaders();
    _showSnackBar('Đã cập nhật "${updated.name}"', isError: false);
  }

  Future<void> _openSuspend(ReaderView reader) async {
    final reason = await showDialog<String>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => _SuspendModal(readerName: reader.name),
    );
    if (reason == null || !mounted) return;
    final result = await _service.suspend(
        reader.id, SuspendRequest(reason: reason));
    if (!mounted) return;
    if (result.isSuccess) {
      await _loadReaders();
      _showSnackBar('Đã khoá tài khoản "${reader.name}"', isError: false);
    } else {
      _showSnackBar(result.errorMessage ?? 'Khoá thất bại', isError: true);
    }
  }

  Future<void> _unsuspend(ReaderView reader) async {
    final confirm = await showDialog<bool>(
          context: context,
          barrierColor: const Color(0x80000000),
          builder: (_) => _ConfirmDialog(
            title:        'Mở khoá tài khoản',
            message:      'Xác nhận mở khoá tài khoản của "${reader.name}"?',
            confirmLabel: 'Mở khoá',
            confirmColor: const Color(0xFF16A34A),
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;
    final result = await _service.unsuspend(reader.id);
    if (!mounted) return;
    if (result.isSuccess) {
      await _loadReaders();
      _showSnackBar('Đã mở khoá "${reader.name}"', isError: false);
    } else {
      _showSnackBar(result.errorMessage ?? 'Mở khoá thất bại', isError: true);
    }
  }

  Future<void> _openExtend(ReaderView reader) async {
    final newDate = await showDialog<DateTime>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => _ExtendMembershipModal(reader: reader),
    );
    if (newDate == null || !mounted) return;
    final result = await _service.extendMembership(
        reader.id, ExtendMemberShipRequest(newExpireDate: newDate));
    if (!mounted) return;
    if (result.isSuccess) {
      await _loadReaders();
      _showSnackBar(
          'Đã gia hạn thẻ cho "${reader.name}" đến ${_dateFormat.format(newDate)}',
          isError: false);
    } else {
      _showSnackBar(result.errorMessage ?? 'Gia hạn thất bại', isError: true);
    }
  }

  Future<void> _deleteReader(ReaderView reader) async {
    final confirm = await showDialog<bool>(
          context: context,
          barrierColor: const Color(0x80000000),
          builder: (_) => _ConfirmDialog(
            title:        'Xoá độc giả',
            message:
                'Bạn có chắc muốn xoá "${reader.name}"?\nHành động này không thể hoàn tác.',
            confirmLabel: 'Xoá',
            confirmColor: const Color(0xFFDC2626),
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;

    final result = await _service.delete(reader.id);
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _readers.removeWhere((r) => r.id == reader.id);
        _applyFilter();
      });
      _showSnackBar('Đã xoá "${reader.name}"', isError: false);
    } else {
      _showSnackBar(result.errorMessage ?? 'Xoá thất bại', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Table columns
  // ─────────────────────────────────────────────────────────────

  // AppTable padding nội bộ: horizontal 20px × 2 = 40px.
  // _buildRowActions: 5 icon × 30px + 4 gap × 4px = 166px.
  //
  // tableWidth = width widget của AppTable − 40px padding nội bộ.
  //   narrow  (tableWidth < 380): Họ tên + icon ⋮
  //   compact (tableWidth < 620): Họ tên + Trạng thái + Thao tác (166px)
  //   wide   (tableWidth ≥ 620):  đủ cột
  List<AppTableColumn<ReaderView>> _buildColumns(double width) {
    final tableWidth = width - 40;
    final isNarrow  = tableWidth < 380;
    final isCompact = tableWidth < 620;

    final nameCol = AppTableColumn<ReaderView>(
      label: 'Họ tên / Email',
      flex: 3,
      sortable: true,
      sortKey: 'name',
      builder: (r) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(r.name,
              style: TextStyle(
                  fontSize: isNarrow ? 13.0 : 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
          const SizedBox(height: 2),
          Text(r.email,
              style: TextStyle(
                  fontSize: isNarrow ? 11.0 : 12.0,
                  color: const Color(0xFF9CA3AF)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ],
      ),
    );

    final statusCol = AppTableColumn<ReaderView>(
      label: 'Trạng thái',
      flex: 2,
      sortable: true,
      sortKey: 'status',
      builder: (r) => _ReaderStatusBadge(reader: r),
    );

    if (isNarrow) {
      return [
        nameCol,
        AppTableColumn<ReaderView>(
          label: '',
          fixedWidth: 30,
          builder: (r) => GestureDetector(
            onTap: () => _openDetail(r),
            child: const Icon(Icons.more_vert_rounded,
                size: 18, color: Color(0xFF6B7280)),
          ),
        ),
      ];
    }

    if (isCompact) {
      return [
        nameCol,
        statusCol,
        AppTableColumn<ReaderView>(
          label: 'Thao tác',
          fixedWidth: 166,
          builder: (r) => _buildRowActions(r),
        ),
      ];
    }

    // wide — đủ cột
    return [
      nameCol,
      AppTableColumn<ReaderView>(
        label: 'Số điện thoại',
        flex: 2,
        builder: (r) => Text(r.phone,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF374151))),
      ),
      AppTableColumn<ReaderView>(
        label: 'Hạn thẻ',
        flex: 2,
        sortable: true,
        sortKey: 'expiry',
        builder: (r) {
          final expired = r.isMembershipExpired;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expired)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 13, color: Color(0xFFDC2626)),
                ),
              Text(
                _dateFormat.format(r.membershipExpireAt),
                style: TextStyle(
                  fontSize: 13,
                  color: expired
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF6B7280),
                  fontWeight:
                      expired ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          );
        },
      ),
      statusCol,
      AppTableColumn<ReaderView>(
        label: 'Thao tác',
        fixedWidth: 166,
        builder: (r) => _buildRowActions(r),
      ),
    ];
  }

  Widget _buildRowActions(ReaderView r) {
    final isSuspended = r.status == ReaderStatus.SUSPENDED;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBtn(
          icon:    Icons.visibility_outlined,
          color:   const Color(0xFF6B7280),
          tooltip: 'Xem chi tiết',
          onTap:   () => _openDetail(r),
        ),
        const SizedBox(width: 4),
        _ActionBtn(
          icon:    Icons.edit_outlined,
          color:   const Color(0xFF2563EB),
          tooltip: 'Chỉnh sửa',
          onTap:   () => _openEdit(r),
        ),
        const SizedBox(width: 4),
        _ActionBtn(
          icon:    Icons.card_membership_rounded,
          color:   const Color(0xFF7C3AED),
          tooltip: 'Gia hạn thẻ',
          onTap:   () => _openExtend(r),
        ),
        const SizedBox(width: 4),
        if (isSuspended)
          _ActionBtn(
            icon:    Icons.lock_open_rounded,
            color:   const Color(0xFF16A34A),
            tooltip: 'Mở khoá',
            onTap:   () => _unsuspend(r),
          )
        else
          _ActionBtn(
            icon:    Icons.block_rounded,
            color:   const Color(0xFFDC2626),
            tooltip: 'Khoá tài khoản',
            onTap:   () => _openSuspend(r),
          ),
        const SizedBox(width: 4),
        _ActionBtn(
          icon:    Icons.delete_outline_rounded,
          color:   const Color(0xFFEF4444),
          tooltip: 'Xoá',
          onTap:   () => _deleteReader(r),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

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
            label:     'Thử lại',
            icon:      Icons.refresh_rounded,
            onPressed: _loadReaders,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width     = constraints.maxWidth;
        final isNarrow  = width < 500;
        final isCompact = width < 760;
        final pad       = isNarrow ? 14.0 : isCompact ? 20.0 : 28.0;

        Widget section(Widget child) =>
            Padding(padding: EdgeInsets.symmetric(horizontal: pad), child: child);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────────────────
              section(isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quản lý độc giả',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827))),
                        const SizedBox(height: 2),
                        const Text(
                            'Danh sách toàn bộ độc giả trong thư viện',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label:     'Thêm độc giả',
                            icon:      Icons.person_add_rounded,
                            onPressed: _openCreate,
                          ),
                        ),
                      ],
                    )
                  : Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quản lý độc giả',
                                style: TextStyle(
                                    fontSize: isCompact ? 18 : 22,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827))),
                            const SizedBox(height: 4),
                            const Text(
                                'Danh sách toàn bộ độc giả trong thư viện',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      AppButton(
                        label:     'Thêm độc giả',
                        icon:      Icons.person_add_rounded,
                        onPressed: _openCreate,
                      ),
                    ])),

              const SizedBox(height: 20),

              // ── Stat Cards (luôn xếp hàng ngang, giống audit log) ──
              section(Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.people_outline_rounded,
                      title: 'Tổng độc giả',
                      value: _total,
                      color: const Color(0xFF2563EB),
                      subtitle: 'Trong hệ thống',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Đang hoạt động',
                      value: _normal,
                      color: const Color(0xFF16A34A),
                      subtitle: 'Thẻ còn hạn',
                      onTap: () => _onStatusFilter('NORMAL'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.block_rounded,
                      title: 'Bị khoá',
                      value: _suspended,
                      color: const Color(0xFFDC2626),
                      subtitle: 'Cần xử lý',
                      onTap: () => _onStatusFilter('SUSPENDED'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.card_membership_rounded,
                      title: 'Hết hạn thẻ',
                      value: _expired,
                      color: const Color(0xFFD97706),
                      subtitle: 'Cần gia hạn',
                      onTap: () => _onStatusFilter('expired'),
                    ),
                  ),
                ],
              )),

              const SizedBox(height: 20),

              // ── Toolbar ───────────────────────────────────────────
              section(isNarrow
                  ? Column(
                      children: [
                        SearchBarWidget(
                          hintText:    'Tìm theo tên, email, số điện thoại...',
                          suggestions: _searchSuggestions,
                          onChanged:   _onSearch,
                          onSelect:    _onSearch,
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          FilterPopup(
                            label:      'Trạng thái',
                            selected:   _statusFilter,
                            searchable: false,
                            items: const {
                              'NORMAL':    'Hoạt động',
                              'SUSPENDED': 'Bị khoá',
                              'expired':   'Hết hạn thẻ',
                            },
                            onChanged: (v) =>
                                setState(() { _statusFilter = v; _applyFilter(); }),
                          ),
                          const Spacer(),
                          AppIconButton(
                            icon:      Icons.refresh_rounded,
                            onPressed: _loadReaders,
                            tooltip:   'Tải lại',
                          ),
                        ]),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SearchBarWidget(
                            hintText:    'Tìm theo tên, email, số điện thoại...',
                            suggestions: _searchSuggestions,
                            onChanged:   _onSearch,
                            onSelect:    _onSearch,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilterPopup(
                          label:      'Trạng thái',
                          selected:   _statusFilter,
                          searchable: false,
                          items: const {
                            'NORMAL':    'Hoạt động',
                            'SUSPENDED': 'Bị khoá',
                            'expired':   'Hết hạn thẻ',
                          },
                          onChanged: (v) =>
                              setState(() { _statusFilter = v; _applyFilter(); }),
                        ),
                        const SizedBox(width: 8),
                        AppIconButton(
                          icon:      Icons.refresh_rounded,
                          onPressed: _loadReaders,
                          tooltip:   'Tải lại',
                        ),
                      ],
                    )),

              const SizedBox(height: 6),

              // ── Result count ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(left: pad + 2, bottom: 8),
                child: Text(
                  _filtered.isEmpty
                      ? 'Không tìm thấy kết quả'
                      : 'Hiển thị ${_filtered.length} / $_total độc giả',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFD1D5DB)),
                ),
              ),

              // ── Table ─────────────────────────────────────────────
              section(AppTable<ReaderView>(
                rows:    _filtered,
                columns: _buildColumns(width - pad * 2),
                emptyMessage: _searchText.isNotEmpty
                    ? 'Không tìm thấy độc giả phù hợp với "$_searchText"'
                    : 'Chưa có độc giả nào trong hệ thống',
                cellValue: (r, key) => switch (key) {
                  'name'   => r.name,
                  'expiry' => r.membershipExpireAt,
                  'status' => r.status.index,
                  _        => '',
                },
              )),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _AddReaderModal
// ─────────────────────────────────────────────────────────────

class _AddReaderModal extends StatefulWidget {
  const _AddReaderModal({required this.service});
  final ReaderService service;

  @override
  State<_AddReaderModal> createState() => _AddReaderModalState();
}

class _AddReaderModalState extends State<_AddReaderModal>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _expireDate;

  bool    _isSubmitting = false;
  String? _errorMsg;

  late final AnimationController _animCtrl;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expireDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate:  DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expireDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_expireDate == null) {
      setState(() => _errorMsg = 'Vui lòng chọn ngày hết hạn thẻ.');
      return;
    }

    setState(() { _isSubmitting = true; _errorMsg = null; });

    final request = CreateReaderRequest(
      name:               _nameCtrl.text.trim(),
      email:              _emailCtrl.text.trim(),
      phone:              _phoneCtrl.text.trim(),
      membershipExpireAt: _expireDate!,
    );

    final result = await widget.service.create(request);
    if (!mounted) return;

    if (result.isSuccess) {
      final id     = result.data?['id'] ?? '';
      final detail = await widget.service.findById(id);
      if (mounted) {
        await _animCtrl.reverse();
        Navigator.pop(context, detail.isSuccess ? detail.data : null);
      }
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMsg     = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      controller: _animCtrl,
      width: 560,
      header: AppModalHeader(
        icon:      Icons.person_add_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBg:    const Color(0xFFEFF6FF),
        title:     'Thêm độc giả mới',
        subtitle:  'Điền thông tin để tạo tài khoản độc giả',
        onClose:   _close,
      ),
      footer: AppModalFooter(
        onCancel:     _close,
        onConfirm:    _submit,
        confirmLabel: 'Thêm độc giả',
        confirmIcon:  Icons.person_add_rounded,
        isLoading:    _isSubmitting,
        loadingLabel: 'Đang lưu...',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 4),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên + Email
              Row(children: [
                Expanded(child: AppModalField(
                  label: 'Họ và tên *',
                  controller: _nameCtrl,
                  hint: 'Nguyễn Văn A',
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Tên không được để trống' : null,
                )),
                const SizedBox(width: 16),
                Expanded(child: AppModalField(
                  label: 'Email *',
                  controller: _emailCtrl,
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email không được để trống';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                )),
              ]),
              const SizedBox(height: 16),

              // SĐT + Hạn thẻ
              Row(children: [
                Expanded(child: AppModalField(
                  label: 'Số điện thoại *',
                  controller: _phoneCtrl,
                  hint: '0912 345 678',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Số điện thoại không được để trống';
                    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length < 8 || digits.length > 20)
                      return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                )),
                const SizedBox(width: 16),
                Expanded(child: _DatePickerField(
                  label:    'Ngày hết hạn thẻ *',
                  date:     _expireDate,
                  dateFmt:  _dateFmt,
                  onPick:   _pickDate,
                )),
              ]),

              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMsg!),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _EditReaderModal
// ─────────────────────────────────────────────────────────────

class _EditReaderModal extends StatefulWidget {
  const _EditReaderModal({
    required this.service,
    required this.reader,
  });
  final ReaderService service;
  final ReaderView    reader;

  @override
  State<_EditReaderModal> createState() => _EditReaderModalState();
}

class _EditReaderModalState extends State<_EditReaderModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late DateTime _expireDate;

  bool    _isSubmitting = false;
  String? _errorMsg;

  late final AnimationController _animCtrl;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.reader.name);
    _emailCtrl  = TextEditingController(text: widget.reader.email);
    _phoneCtrl  = TextEditingController(text: widget.reader.phone);
    _expireDate = widget.reader.membershipExpireAt;
    _animCtrl   = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expireDate,
      firstDate:   DateTime(2020),
      lastDate:    DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expireDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isSubmitting = true; _errorMsg = null; });

    final request = UpdateReaderRequest(
      name:               _nameCtrl.text.trim(),
      email:              _emailCtrl.text.trim(),
      phone:              _phoneCtrl.text.trim(),
      membershipExpireAt: _expireDate,
    );

    final result = await widget.service.update(widget.reader.id, request);
    if (!mounted) return;

    if (result.isSuccess) {
      await _animCtrl.reverse();
      if (mounted) Navigator.pop(context, result.data);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMsg     = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      controller: _animCtrl,
      width: 560,
      header: AppModalHeader(
        icon:      Icons.edit_outlined,
        iconColor: const Color(0xFF2563EB),
        iconBg:    const Color(0xFFEFF6FF),
        title:     'Chỉnh sửa độc giả',
        subtitle:  widget.reader.name,
        onClose:   _close,
      ),
      footer: AppModalFooter(
        onCancel:     _close,
        onConfirm:    _submit,
        confirmLabel: 'Lưu thay đổi',
        confirmIcon:  Icons.save_rounded,
        isLoading:    _isSubmitting,
        loadingLabel: 'Đang lưu...',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 4),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: AppModalField(
                  label: 'Họ và tên *',
                  controller: _nameCtrl,
                  hint: 'Nguyễn Văn A',
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Tên không được để trống' : null,
                )),
                const SizedBox(width: 16),
                Expanded(child: AppModalField(
                  label: 'Email *',
                  controller: _emailCtrl,
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email không được để trống';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                )),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: AppModalField(
                  label: 'Số điện thoại *',
                  controller: _phoneCtrl,
                  hint: '0912 345 678',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Số điện thoại không được để trống';
                    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length < 8 || digits.length > 20)
                      return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                )),
                const SizedBox(width: 16),
                Expanded(child: _DatePickerField(
                  label:   'Ngày hết hạn thẻ *',
                  date:    _expireDate,
                  dateFmt: _dateFmt,
                  onPick:  _pickDate,
                  hasValue: true,
                )),
              ]),

              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMsg!),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ReaderDetailModal
// ─────────────────────────────────────────────────────────────

class _ReaderDetailModal extends StatefulWidget {
  const _ReaderDetailModal({required this.reader});
  final ReaderView reader;

  @override
  State<_ReaderDetailModal> createState() => _ReaderDetailModalState();
}

class _ReaderDetailModalState extends State<_ReaderDetailModal>
    with SingleTickerProviderStateMixin {
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final reader = widget.reader;
    return AppModal(
      controller: _animCtrl,
      width: 480,
      header: AppModalHeader(
        icon:      Icons.person_outline_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBg:    const Color(0xFFEFF6FF),
        title:     reader.name,
        subtitle:  reader.id,
        onClose:   _close,
      ),
      footer: AppModalFooter(
        onCancel:        _close,
        onConfirm:       _close,
        cancelLabel:     '',
        confirmLabel:    'Đóng',
        showRequiredHint: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge + suspend reason
            Row(children: [
              _ReaderStatusBadge(reader: reader),
              if (reader.suspendReason != null &&
                  reader.suspendReason!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lý do: ${reader.suspendReason}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ]),

            const SizedBox(height: 16),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(children: [
                _DetailRow(
                    icon:  Icons.alternate_email_rounded,
                    label: 'Email',
                    value: reader.email),
                const SizedBox(height: 12),
                _DetailRow(
                    icon:  Icons.phone_outlined,
                    label: 'Số điện thoại',
                    value: reader.phone),
                const SizedBox(height: 12),
                _DetailRow(
                    icon:       Icons.card_membership_rounded,
                    label:      'Hạn thẻ',
                    value:      _dateFmt.format(reader.membershipExpireAt),
                    valueColor: reader.isMembershipExpired
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A)),
              ]),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _SuspendModal — nhập lý do khoá
// ─────────────────────────────────────────────────────────────

class _SuspendModal extends StatefulWidget {
  const _SuspendModal({required this.readerName});
  final String readerName;

  @override
  State<_SuspendModal> createState() => _SuspendModalState();
}

class _SuspendModalState extends State<_SuspendModal>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _close([String? result]) async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      controller: _animCtrl,
      width: 420,
      header: AppModalHeader(
        icon:      Icons.block_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBg:    const Color(0xFFFEF2F2),
        title:     'Khoá tài khoản',
        subtitle:  widget.readerName,
        onClose:   () => _close(),
      ),
      footer: AppModalFooter(
        onCancel:     () => _close(),
        onConfirm:    () {
          if (_formKey.currentState?.validate() ?? false) {
            _close(_reasonCtrl.text.trim());
          }
        },
        confirmLabel: 'Khoá tài khoản',
        confirmIcon:  Icons.block_rounded,
        showRequiredHint: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 4),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppModalField(
                label:    'Lý do khoá *',
                controller: _reasonCtrl,
                hint:     'Nhập lý do khoá tài khoản...',
                maxLines: 3,
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Vui lòng nhập lý do' : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ExtendMembershipModal
// ─────────────────────────────────────────────────────────────

class _ExtendMembershipModal extends StatefulWidget {
  const _ExtendMembershipModal({required this.reader});
  final ReaderView reader;

  @override
  State<_ExtendMembershipModal> createState() =>
      _ExtendMembershipModalState();
}

class _ExtendMembershipModalState extends State<_ExtendMembershipModal>
    with SingleTickerProviderStateMixin {
  DateTime? _newDate;
  late final AnimationController _animCtrl;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _close([DateTime? result]) async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _pickDate() async {
    final initial =
        widget.reader.membershipExpireAt.isAfter(DateTime.now())
            ? widget.reader.membershipExpireAt
            : DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: initial.add(const Duration(days: 365)),
      firstDate:   DateTime.now().add(const Duration(days: 1)),
      lastDate:    DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF7C3AED)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _newDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final reader = widget.reader;
    return AppModal(
      controller: _animCtrl,
      width: 400,
      header: AppModalHeader(
        icon:      Icons.card_membership_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg:    const Color(0xFFF5F3FF),
        title:     'Gia hạn thẻ thành viên',
        subtitle:  reader.name,
        onClose:   () => _close(),
      ),
      footer: AppModalFooter(
        onCancel:     () => _close(),
        onConfirm:    _newDate != null ? () => _close(_newDate) : () {},
        confirmLabel: 'Xác nhận gia hạn',
        confirmIcon:  Icons.card_membership_rounded,
        showRequiredHint: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 4),
        child: Column(
          children: [
            // Hạn hiện tại → Hạn mới
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hạn hiện tại',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF))),
                    Text(
                      _dateFmt.format(reader.membershipExpireAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: reader.isMembershipExpired
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hạn mới',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF))),
                    _newDate != null
                        ? Text(
                            _dateFmt.format(_newDate!),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C3AED)),
                          )
                        : const Text('Chưa chọn',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFD1D5DB))),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                label:    _newDate == null
                    ? 'Chọn ngày gia hạn'
                    : 'Đổi ngày gia hạn',
                icon:     Icons.calendar_today_rounded,
                variant:  AppButtonVariant.secondary,
                onPressed: _pickDate,
                fullWidth: true,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ConfirmDialog — xác nhận đơn giản (xoá / mở khoá)
// ─────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final Color  confirmColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60),
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color:      Color(0x20000000),
                blurRadius: 32,
                offset:     Offset(0, 12)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Column(children: [
              Text(title,
                  style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF111827))),
              const SizedBox(height: 10),
              Text(message,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: AppButton(
                label:   'Huỷ',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(context, false),
              )),
              const SizedBox(width: 10),
              Expanded(child: _SolidButton(
                label: confirmLabel,
                color: confirmColor,
                onTap: () => Navigator.pop(context, true),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ReaderStatusBadge
// ─────────────────────────────────────────────────────────────

class _ReaderStatusBadge extends StatelessWidget {
  const _ReaderStatusBadge({required this.reader});
  final ReaderView reader;

  @override
  Widget build(BuildContext context) {
    final (label, textColor, bgColor) = switch (reader.status) {
      ReaderStatus.SUSPENDED => (
          'Bị khoá',
          const Color(0xFFDC2626),
          const Color(0xFFFEF2F2),
        ),
      ReaderStatus.NORMAL when reader.isMembershipExpired => (
          'Hết hạn thẻ',
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
        ),
      _ => (
          'Hoạt động',
          const Color(0xFF16A34A),
          const Color(0xFFF0FDF4),
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _DetailRow — dòng thông tin trong modal
// ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
    return Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 8),
      SizedBox(
        width: 110,
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9CA3AF))),
      ),
      Expanded(
        child: Text(value,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w500,
              color:      valueColor ?? const Color(0xFF111827),
            )),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  _DatePickerField — date picker field dùng trong modal form
// ─────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.dateFmt,
    required this.onPick,
    this.hasValue = false,
  });
  final String    label;
  final DateTime? date;
  final DateFormat dateFmt;
  final VoidCallback onPick;
  final bool      hasValue;

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null || hasValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      Color(0xFF374151))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size:  15,
                  color: hasDate
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFD1D5DB)),
              const SizedBox(width: 8),
              Text(
                date != null
                    ? dateFmt.format(date!)
                    : 'Chọn ngày...',
                style: TextStyle(
                  fontSize: 13,
                  color: date != null
                      ? const Color(0xFF111827)
                      : const Color(0xFFD1D5DB),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ErrorBanner — error message trong form
// ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.error_outline_rounded,
          size: 14, color: Color(0xFFEF4444)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(message,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFFEF4444))),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  _ActionBtn — icon button nhỏ có hover + tooltip
// ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:      widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width:  30,
            height: 30,
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

// ─────────────────────────────────────────────────────────────
//  _SolidButton — nút màu tuỳ chỉnh (dùng trong _ConfirmDialog)
// ─────────────────────────────────────────────────────────────

class _SolidButton extends StatefulWidget {
  const _SolidButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  @override
  State<_SolidButton> createState() => _SolidButtonState();
}

class _SolidButtonState extends State<_SolidButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 100),
        height:    40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.85)
              : widget.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(widget.label,
            style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      Colors.white)),
      ),
    );
  }
}