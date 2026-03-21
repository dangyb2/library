import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import '../models/borrow.dart';
import '../services/borrow_service.dart';
import '../services/book_service.dart';
import '../gateway/api_gateway.dart';
import '../widgets/custom_modal.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_table.dart'  hide TableActions;
import '../widgets/search_bar.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_filter.dart';
import '../widgets/custom_dropdown.dart';

// ─────────────────────────────────────────────
//  BORROW PAGE
// ─────────────────────────────────────────────

class BorrowPage extends StatefulWidget {
  const BorrowPage({super.key});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage>
    with TickerProviderStateMixin {
  final BorrowService _service     = BorrowService();
  final BookService  _bookService  = BookService();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // ── state ──────────────────────────────────
  List<BorrowSummaryView> _allBorrows = [];
  List<BorrowSummaryView> _filtered   = [];
  List<OverdueBorrowView> _overdues   = [];
  bool _isLoading    = true;
  bool _isPayingFine = false;
  String _search  = '';
  BorrowStatus? _statusFilter;

  // ── modal animation ────────────────────────
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

  // ── data ───────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final [borrows, overdues] = await Future.wait([
      _service.listAllBorrows(),
      _service.getOverdueBorrows(),
    ]);

    final b = (borrows as ServiceResult<List<BorrowSummaryView>>).data ?? [];
    final o = (overdues as ServiceResult<List<OverdueBorrowView>>).data ?? [];

    setState(() {
      _allBorrows  = b;
      _overdues    = o;
      _isLoading   = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allBorrows.where((b) {
        final matchSearch = _search.isEmpty ||
            b.bookTitle.toLowerCase().contains(_search.toLowerCase()) ||
            b.readerName.toLowerCase().contains(_search.toLowerCase()) ||
            b.borrowId.toLowerCase().contains(_search.toLowerCase());
        final matchStatus =
            _statusFilter == null || b.status == _statusFilter;
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  // ── stats helpers ──────────────────────────

  int get _countBorrowed  =>
      _allBorrows.where((b) => b.status == BorrowStatus.BORROWED).length;
  int get _countOverdue   => _overdues.length;
  int get _countReturned  =>
      _allBorrows.where((b) => b.status == BorrowStatus.RETURNED).length;
  int get _countLost      =>
      _allBorrows.where((b) => b.status == BorrowStatus.LOST).length;
  int get _countCancelled =>
      _allBorrows.where((b) => b.status == BorrowStatus.CANCELLED).length;


  // ── modal helpers ──────────────────────────

  void _openModal(Widget Function(AnimationController) builder) {
    _modalCtrl.forward(from: 0);
    showDialog(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => builder(_modalCtrl),
    );
  }

  void _closeModal() {
    _modalCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  // ── snackbar ───────────────────────────────

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
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

  // ── PAGE HEADER ────────────────────────────

  Widget _buildPageHeader() {
    return Row(
      children: [
        // Title block
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý Mượn / Trả',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tổng ${_allBorrows.length} phiếu mượn',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),

        const Spacer(),

        // Overdue badge
        if (_countOverdue > 0)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 15, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text(
                  '$_countOverdue phiếu quá hạn',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),

        AppButton(
          label: 'Tạo phiếu mượn',
          icon: Icons.add_rounded,
          onPressed: () => _openBorrowModal(),
        ),
      ],
    );
  }

  // ── STAT CARDS ─────────────────────────────

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Đang mượn',
            value: _countBorrowed,
            color: const Color(0xFF2563EB),
            subtitle: 'phiếu đang hoạt động',
            onTap: () => setState(() {
              _statusFilter = _statusFilter == BorrowStatus.BORROWED
                  ? null
                  : BorrowStatus.BORROWED;
              _applyFilter();
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.warning_amber_rounded,
            title: 'Quá hạn',
            value: _countOverdue,
            color: const Color(0xFFDC2626),
            subtitle: 'cần xử lý ngay',
            onTap: () => setState(() {
              _statusFilter = _statusFilter == BorrowStatus.OVERDUE
                  ? null
                  : BorrowStatus.OVERDUE;
              _applyFilter();
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Đã trả',
            value: _countReturned,
            color: const Color(0xFF16A34A),
            subtitle: 'lượt trả thành công',
            onTap: () => setState(() {
              _statusFilter = _statusFilter == BorrowStatus.RETURNED
                  ? null
                  : BorrowStatus.RETURNED;
              _applyFilter();
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Báo mất',
            value: _countLost,
            color: const Color(0xFFD97706),
            subtitle: 'sách bị mất',
            onTap: () => setState(() {
              _statusFilter = _statusFilter == BorrowStatus.LOST
                  ? null
                  : BorrowStatus.LOST;
              _applyFilter();
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.cancel_outlined,
            title: 'Đã huỷ',
            value: _countCancelled,
            color: const Color(0xFF6B7280),
            subtitle: 'phiếu bị huỷ',
            onTap: () => setState(() {
              _statusFilter = _statusFilter == BorrowStatus.CANCELLED
                  ? null
                  : BorrowStatus.CANCELLED;
              _applyFilter();
            }),
          ),
        ),
      ],
    );
  }

  // ── TABLE SECTION ──────────────────────────

  Widget _buildTableSection() {
    return Column(
      children: [
        // Toolbar
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SearchBarWidget(
                hintText: 'Tìm theo tên sách, tên độc giả...',
                suggestions:
                    _allBorrows.map((b) => b.bookTitle).toList() +
                    _allBorrows.map((b) => b.readerName).toList(),
                onChanged: (v) { _search = v; _applyFilter(); },
                onSelect:  (v) { _search = v; _applyFilter(); },
              ),
            ),
            const SizedBox(width: 12),
            FilterPopup(
              label: 'Trạng thái',
              selected: _statusFilter?.name,
              searchable: false,
              items: const {
                'BORROWED':  'Đang mượn',
                'RETURNED':  'Đã trả',
                'OVERDUE':   'Quá hạn',
                'LOST':      'Mất sách',
                'CANCELLED': 'Đã huỷ',
              },
              onChanged: (v) {
                setState(() => _statusFilter = v == null
                    ? null
                    : BorrowStatusX.fromString(v));
                _applyFilter();
              },
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Làm mới',
              variant: AppButtonVariant.secondary,
              icon: Icons.refresh_rounded,
              onPressed: _loadData,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTable<BorrowSummaryView>(
          rows: _filtered,
          emptyMessage: 'Không có phiếu mượn nào',
          columns: [
            AppTableColumn(
              label: 'Tên Sách',
              flex: 2,
              builder: (row) => Text(
                row.bookTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppTableColumn(
              label: 'Tên độc giả',
              flex: 2,
              builder: (row) => Text(
                row.readerName,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppTableColumn(
              label: 'Ngày mượn',
              flex: 2,
              builder: (row) => Text(
                _dateFormat.format(row.borrowDate),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
            AppTableColumn(
              label: 'Hạn trả',
              flex: 2,
              builder: (row) {
                final overdue = row.status == BorrowStatus.OVERDUE;
                return Row(
                  children: [
                    if (overdue)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.warning_amber_rounded,
                            size: 13, color: Color(0xFFDC2626)),
                      ),
                    Text(
                      _dateFormat.format(row.dueDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: overdue
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF6B7280),
                        fontWeight: overdue
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                );
              },
            ),
            AppTableColumn(
              label: 'Trạng thái',
              flex: 2,
              builder: (row) => _BorrowStatusBadge(row.status),
            ),
            AppTableColumn(
              label: 'Thao tác',
              fixedWidth: 190,
              builder: (row) => _buildRowActions(row),
            ),
          ],
        ),
      ],
    );
  }

  // ── ROW ACTIONS ────────────────────────────

  Widget _buildRowActions(BorrowSummaryView row) {
    final canReturn = row.status == BorrowStatus.BORROWED ||
        row.status == BorrowStatus.OVERDUE;
    final canCancel = row.status == BorrowStatus.BORROWED;
    final canUndo   = row.status == BorrowStatus.CANCELLED;
    final canEdit   = row.status == BorrowStatus.BORROWED ||
        row.status == BorrowStatus.OVERDUE;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Xem chi tiết
        Tooltip(
          message: 'Xem chi tiết',
          child: _ActionIconBtn(
            icon: Icons.visibility_outlined,
            color: const Color(0xFF6B7280),
            onTap: () => _openDetailModal(row.borrowId),
          ),
        ),

        // Sửa phiếu — khi đang mượn hoặc quá hạn
        if (canEdit)
          Tooltip(
            message: 'Sửa phiếu',
            child: _ActionIconBtn(
              icon: Icons.edit_outlined,
              color: const Color(0xFF2563EB),
              onTap: () => _openEditModal(row),
            ),
          ),

        // Gia hạn — chỉ khi đang mượn
        if (row.status == BorrowStatus.BORROWED)
          Tooltip(
            message: 'Gia hạn',
            child: _ActionIconBtn(
              icon: Icons.update_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () => _openExtendModal(row),
            ),
          ),

        // Trả sách & Báo mất — gộp thành 1 nút
        if (canReturn)
          Tooltip(
            message: 'Trả sách / Báo mất',
            child: _ActionIconBtn(
              icon: Icons.assignment_return_outlined,
              color: const Color(0xFF16A34A),
              onTap: () => _openReturnOrLostModal(row),
            ),
          ),

        // Huỷ phiếu — chỉ khi đang mượn
        if (canCancel)
          Tooltip(
            message: 'Huỷ phiếu',
            child: _ActionIconBtn(
              icon: Icons.cancel_outlined,
              color: const Color(0xFFEF4444),
              onTap: () => _confirmCancelBorrow(row),
            ),
          ),

        // Hoàn tác huỷ — chỉ khi đã huỷ
        if (canUndo)
          Tooltip(
            message: 'Hoàn tác huỷ',
            child: _ActionIconBtn(
              icon: Icons.undo_rounded,
              color: const Color(0xFF2563EB),
              onTap: () => _confirmUndoCancel(row),
            ),
          ),
      ],
    );
  }

  // ────────────────────────────────────────────
  //  MODALS
  // ────────────────────────────────────────────

  // ── 1. Tạo phiếu mượn ─────────────────────

  void _openBorrowModal() {
    final dueDateCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    BookCondition condition = BookCondition.GOOD;
    DateTime? dueDate;
    bool isLoading = false;

    // Lưu id + name của reader/book được chọn
    String? selectedReaderId;
    String? selectedReaderName;
    String? selectedBookId;
    String? selectedBookName;

    _openModal((ctrl) => StatefulBuilder(
      builder: (ctx, setLocal) => AppModal(
        controller: ctrl,
        width: 580,
        header: AppModalHeader(
          icon: Icons.add_card_rounded,
          title: 'Tạo phiếu mượn',
          subtitle: 'Chọn độc giả và sách để tạo phiếu mượn mới',
          onClose: _closeModal,
        ),
        footer: AppModalFooter(
          onCancel: _closeModal,
          confirmLabel: 'Tạo phiếu',
          confirmIcon: Icons.check_rounded,
          isLoading: isLoading,
          onConfirm: () async {
            if (!formKey.currentState!.validate()) return;
            if (selectedReaderId == null) {
              _toast('Vui lòng chọn độc giả', error: true); return;
            }
            if (selectedBookId == null) {
              _toast('Vui lòng chọn sách', error: true); return;
            }
            setLocal(() => isLoading = true);
            final result = await _service.borrowBook(BorrowRequest(
              readerId: selectedReaderId!,
              bookId:   selectedBookId!,
              dueDate:  dueDate!,
              conditionBorrow: condition,
            ));
            setLocal(() => isLoading = false);
            if (result.isSuccess) {
              _closeModal();
              _toast('Tạo phiếu mượn thành công!');
              _loadData();
            } else {
              _toast(result.errorMessage ?? 'Lỗi', error: true);
            }
          },
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [

              // ── Chọn độc giả ──────────────────────
              _SearchSelectField(
                label: 'Độc giả *',
                hint: 'Tìm và chọn độc giả...',
                selectedName: selectedReaderName,
                icon: Icons.person_outline_rounded,
                fetchItems: () async {
                  try {
                    final res = await AppGateway.instance.reader.get('/readers');
                    final list = res.asList();
                    return list.map((e) => _SelectItem(
                      id:       (e['id'] ?? e['readerId'] ?? '').toString(),
                      name:     (e['name'] ?? e['fullName'] ?? '').toString(),
                      subtitle: (e['email'] ?? '').toString(),
                    )).where((i) => i.id.isNotEmpty).toList();
                  } catch (_) { return []; }
                },
                onSelected: (item) => setLocal(() {
                  selectedReaderId   = item.id;
                  selectedReaderName = item.name;
                }),
                onCleared: () => setLocal(() {
                  selectedReaderId   = null;
                  selectedReaderName = null;
                }),
              ),

              const SizedBox(height: 16),

              // ── Chọn sách ─────────────────────────
              _SearchSelectField(
                label: 'Sách *',
                hint: 'Tìm và chọn sách...',
                selectedName: selectedBookName,
                icon: Icons.menu_book_outlined,
                fetchItems: () async {
                  final result = await _bookService.fetchBooks();
                  if (result case Success(:final data)) {
                    return data.map((b) => _SelectItem(
                      id:       b.id,
                      name:     b.title,
                      subtitle: b.author,
                      extra:    b.availableStock > 0
                                    ? 'Còn ${b.availableStock}'
                                    : 'Hết hàng',
                      extraOk:  b.availableStock > 0,
                    )).toList();
                  }
                  return [];
                },
                onSelected: (item) => setLocal(() {
                  selectedBookId   = item.id;
                  selectedBookName = item.name;
                }),
                onCleared: () => setLocal(() {
                  selectedBookId   = null;
                  selectedBookName = null;
                }),
              ),

              const SizedBox(height: 16),

              // ── Ngày hạn trả ──────────────────────
              AppModalField(
                label: 'Ngày hạn trả *',
                controller: dueDateCtrl,
                hint: 'Chọn ngày hạn trả',
                readOnly: true,
                suffixIcon: const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate:   DateTime.now().add(const Duration(days: 1)),
                    lastDate:    DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setLocal(() {
                      dueDate = picked;
                      dueDateCtrl.text = _dateFormat.format(picked);
                    });
                  }
                },
                validator: (_) => dueDate == null ? 'Vui lòng chọn ngày hạn trả' : null,
              ),

              const SizedBox(height: 16),

              _ConditionDropdown(
                label: 'Tình trạng sách *',
                value: condition,
                onChanged: (v) => setLocal(() => condition = v),
              ),
            ]),
          ),
        ),
      ),
    ));
  }
// ────────────────────────────────────────────
  Future<void> _openBookDetailById(String bookId, String bookTitle) async {
    final result = await _bookService.fetchBookById(bookId);
    if (!mounted) return;

    switch (result) {
      case Failure(:final message):
        _toast(message, error: true);
      case Success(:final data):
        // Dùng _BookDetailDialog với controller riêng —
        // KHÔNG dùng _modalCtrl chung để tránh reverse animation
        // của modal phiếu mượn phía dưới khi đóng
        await showDialog<void>(
          context: context,
          barrierColor: const Color(0x60000000),
          builder: (_) => _BookDetailDialog(data: data),
        );
    }
  }
  // ── 2. Chi tiết phiếu ─────────────────────

  void _openDetailModal(String borrowId) async {
    final result = await _service.getBorrowDetails(borrowId);
    if (!mounted) return;
    if (result.isFailure) { _toast(result.errorMessage!, error: true); return; }
    final d = result.data!;

    final (statusLabel, statusBg, statusFg) = switch (d.status) {
      BorrowStatus.BORROWED  => ('Đang mượn', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
      BorrowStatus.RETURNED  => ('Đã trả',    const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
      BorrowStatus.OVERDUE   => ('Quá hạn',   const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
      BorrowStatus.LOST      => ('Mất sách',  const Color(0xFFFFFBEB), const Color(0xFFD97706)),
      BorrowStatus.CANCELLED => ('Đã huỷ',   const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };

    _openModal((ctrl) => AppModal(
      controller: ctrl,
      width: 600,
      header: AppModalHeader(
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBg: const Color(0xFFEFF6FF),
        title: 'Chi tiết phiếu mượn',
        subtitle: d.borrowId,
        onClose: _closeModal,
      ),
      footer: AppModalFooter(
        onCancel: _closeModal,
        onConfirm: _closeModal,
        confirmLabel: 'Đóng',
        cancelLabel: '',
        showRequiredHint: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Card: Sách & Độc giả ──────────────
          _DetailCard(
            children: [
              // Sách
              InkWell(
                onTap: () => _openBookDetailById(d.bookId, d.bookTitle),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          size: 20, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sách', style: TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 2),
                        Text(
                          d.bookTitle.isNotEmpty ? d.bookTitle : d.bookId,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827)),
                        ),
                      ],
                    )),
                    const Icon(Icons.open_in_new_rounded,
                        size: 14, color: Color(0xFF7C3AED)),
                  ]),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              // Độc giả
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        size: 20, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Độc giả', style: TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 2),
                      Text(
                        d.readerName.isNotEmpty ? d.readerName : d.readerId,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827)),
                      ),
                      if (d.readerId.isNotEmpty)
                        Text('ID: ${d.readerId}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  )),
                ]),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Card: Thời gian ───────────────────
          _DetailCard(
            title: 'Thời gian',
            icon: Icons.calendar_today_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(children: [
                  _CardRow('Ngày mượn',
                      _dateFormat.format(d.borrowDate),
                      icon: Icons.login_rounded,
                      iconColor: const Color(0xFF2563EB)),
                  const SizedBox(height: 10),
                  _CardRow('Hạn trả',
                      _dateFormat.format(d.dueDate),
                      icon: Icons.event_rounded,
                      iconColor: d.status == BorrowStatus.OVERDUE
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF6B7280),
                      valueColor: d.status == BorrowStatus.OVERDUE
                          ? const Color(0xFFDC2626) : null),
                  if (d.returnDate != null) ...[
                    const SizedBox(height: 10),
                    _CardRow('Ngày trả',
                        _dateFormat.format(d.returnDate!),
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFF16A34A)),
                  ],
                ]),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Card: Tình trạng & Trạng thái ─────
          _DetailCard(
            title: 'Tình trạng',
            icon: Icons.info_outline_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _LabelValue(
                      label: 'Khi mượn',
                      value: _conditionVi(d.conditionBorrow),
                    )),
                    if (d.conditionReturn != null)
                      Expanded(child: _LabelValue(
                        label: 'Khi trả',
                        value: _conditionVi(d.conditionReturn!),
                      )),
                    Expanded(child: _LabelValue(
                      label: 'Trạng thái',
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusFg)),
                      ),
                    )),
                  ]),
                ]),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Card: Tài chính ───────────────────
          _DetailCard(
            title: 'Tài chính',
            icon: Icons.payments_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _LabelValue(
                      label: 'Giá thuê',
                      value: '${_fmtCurrency(d.price)} đ',
                    )),
                    Expanded(child: _LabelValue(
                      label: 'Tiền phạt',
                      value: '${_fmtCurrency(d.fine)} đ',
                      valueColor: d.fine > 0
                          ? const Color(0xFFDC2626) : null,
                    )),
                    Expanded(child: _LabelValue(
                      label: 'Thanh toán',
                      valueWidget: _PaymentBadge(status: d.paymentStatus),
                    )),
                  ]),
                  if (d.fine > 0 && d.paymentStatus == PaymentStatus.UNPAID) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _PayFineButton(
                        fine: d.fine,
                        isLoading: _isPayingFine,
                        onTap: () => _confirmPayFine(d),
                      ),
                    ),
                  ],
                ]),
              ),
            ],
          ),

          const SizedBox(height: 4),
        ]),
      ),
    ));
  }

  String _conditionVi(BookCondition c) => switch (c) {
    BookCondition.NEW     => 'Mới',
    BookCondition.GOOD    => 'Tốt',
    BookCondition.WORN    => 'Cũ',
    BookCondition.DAMAGED => 'Hư hỏng',
  };

  String _fmtCurrency(double v) {
    if (v == 0) return '0';
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  // ── Thanh toán tiền phạt ──────────────────

  Future<void> _confirmPayFine(BorrowDetailsView d) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => _PayFineConfirmDialog(
        borrowId:  d.borrowId,
        bookTitle: d.bookTitle.isNotEmpty ? d.bookTitle : d.bookId,
        fine:      d.fine,
      ),
    ) ?? false;
    if (!confirm || !mounted) return;

    setState(() => _isPayingFine = true);
    final result = await _service.payFine(d.borrowId);
    if (!mounted) return;
    setState(() => _isPayingFine = false);

    if (result.isSuccess) {
      Navigator.of(context).pop();
      await _loadData();
      _toast('Thanh toán tiền phạt thành công!');
    } else if (result.errorMessage != null) {
      _toast(result.errorMessage!, error: true);
    }
  }

  // ── 3. Trả sách ───────────────────────────

  // ── 3. Trả sách / Báo mất (gộp) ──────────

  void _openReturnOrLostModal(BorrowSummaryView row) {
    BookCondition condition  = BookCondition.GOOD;
    bool isLoading           = false;
    bool isReturning         = true;
    bool previewLoading      = true;
    ReturnPreviewResult? preview;

    // Load preview ngay khi mở modal
    Future<void> loadPreview(Function setLocal) async {
      try {
        final result = await _service.getReturnPreview(row.borrowId);
        if (result.isSuccess) setLocal(() { preview = result.data; previewLoading = false; });
        else setLocal(() => previewLoading = false);
      } catch (_) { setLocal(() => previewLoading = false); }
    }

    _openModal((ctrl) => StatefulBuilder(
      builder: (ctx, setLocal) {
        // Load preview lần đầu
        if (previewLoading && preview == null) {
          loadPreview(setLocal);
        }
        return AppModal(
        controller: ctrl,
        width: 500,
        header: AppModalHeader(
          icon: Icons.assignment_return_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFF0FDF4),
          title: 'Trả sách / Báo mất',
          subtitle: 'Phiếu: ${row.borrowId}',
          onClose: _closeModal,
        ),
        footer: AppModalFooter(
          onCancel: _closeModal,
          confirmLabel: isReturning ? 'Xác nhận trả' : 'Xác nhận báo mất',
          confirmIcon: isReturning
              ? Icons.check_circle_outline_rounded
              : Icons.report_outlined,
          isLoading: isLoading,
          onConfirm: () async {
            setLocal(() => isLoading = true);
            if (isReturning) {
              final result = await _service.returnBook(
                row.borrowId,
                ReturnRequest(conditionReturn: condition),
              );
              setLocal(() => isLoading = false);
              if (result.isSuccess) {
                _closeModal();
                final d           = result.data!;
                final fine        = d.fine;
                final totalAmount = d.totalAmount ?? d.finalPrice;
                String msg = 'Trả sách thành công!';
                if (fine > 0 && totalAmount != null) {
                  msg = 'Trả sách thành công! '
                      'Tiền phạt: ${fine.toStringAsFixed(0)}đ  •  '
                      'Tổng: ${totalAmount.toStringAsFixed(0)}đ';
                } else if (fine > 0) {
                  msg = 'Trả sách thành công! Tiền phạt: ${fine.toStringAsFixed(0)}đ';
                } else if (totalAmount != null && totalAmount > 0) {
                  msg = 'Trả sách thành công! Tổng: ${totalAmount.toStringAsFixed(0)}đ';
                }
                _toast(msg);
                _loadData();
              } else {
                _toast(result.errorMessage!, error: true);
              }
            } else {
              final result = await _service.reportLost(row.borrowId);
              setLocal(() => isLoading = false);
              if (result.isSuccess) {
                _closeModal();
                _toast('Đã báo mất! Tiền phạt: ${result.data!.toStringAsFixed(0)}đ');
                _loadData();
              } else {
                _toast(result.errorMessage!, error: true);
              }
            }
          },
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info phiếu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _DetailRow('Tên sách',   row.bookTitle.isNotEmpty ? row.bookTitle : row.bookId),
                    _DetailRow('Độc giả',    row.readerName),
                    _DetailRow('Ngày mượn',  _dateFormat.format(row.borrowDate)),
                    _DetailRow('Hạn trả',    _dateFormat.format(row.dueDate)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Toggle trả / báo mất
              const Text('Loại xử lý *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      icon: Icons.assignment_return_outlined,
                      label: 'Trả sách',
                      selected: isReturning,
                      color: const Color(0xFF16A34A),
                      onTap: () => setLocal(() => isReturning = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleOption(
                      icon: Icons.report_outlined,
                      label: 'Báo mất',
                      selected: !isReturning,
                      color: const Color(0xFFD97706),
                      onTap: () => setLocal(() => isReturning = false),
                    ),
                  ),
                ],
              ),

              // Condition dropdown — chỉ hiện khi trả sách
              if (isReturning) ...[
                const SizedBox(height: 20),
                _ConditionDropdown(
                  label: 'Tình trạng sách khi trả *',
                  value: condition,
                  onChanged: (v) => setLocal(() => condition = v),
                ),
              ],

              // Cảnh báo báo mất
              if (!isReturning) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Độc giả sẽ bị tính phí bồi thường. Hành động này không thể hoàn tác.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Preview tiền khi trả sách
              if (isReturning) ...[
                const SizedBox(height: 20),
                if (previewLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (preview != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: preview!.isOverdue
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: preview!.isOverdue
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(
                            preview!.isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.receipt_outlined,
                            size: 14,
                            color: preview!.isOverdue
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            preview!.isOverdue
                                ? 'Quá hạn ${preview!.daysBorrowed} ngày'
                                : 'Đã mượn ${preview!.daysBorrowed} ngày',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: preview!.isOverdue
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        _PreviewRow('Tiền mượn sách',
                            '${_fmtCurrency(preview!.currentPrice)}đ'),
                        if (preview!.fine > 0)
                          _PreviewRow('Tiền phạt',
                              '${_fmtCurrency(preview!.fine)}đ',
                              valueColor: const Color(0xFFDC2626)),
                        const Divider(height: 16, color: Color(0xFFE5E7EB)),
                        _PreviewRow('Tổng thanh toán',
                            '${_fmtCurrency(preview!.totalAmount)}đ',
                            bold: true),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        );
      },
    ));
  }

  // ── 4. Gia hạn ────────────────────────────

  void _openExtendModal(BorrowSummaryView row) {
    final dueDateCtrl = TextEditingController();
    DateTime? newDueDate;
    bool isLoading = false;

    _openModal((ctrl) => StatefulBuilder(
      builder: (ctx, setLocal) => AppModal(
        controller: ctrl,
        width: 480,
        header: AppModalHeader(
          icon: Icons.update_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBg: const Color(0xFFF5F3FF),
          title: 'Gia hạn mượn',
          subtitle: 'Phiếu: ${row.borrowId}',
          onClose: _closeModal,
        ),
        footer: AppModalFooter(
          onCancel: _closeModal,
          confirmLabel: 'Gia hạn',
          confirmIcon: Icons.update_rounded,
          isLoading: isLoading,
          onConfirm: () async {
            if (newDueDate == null) {
              _toast('Vui lòng chọn ngày gia hạn', error: true);
              return;
            }
            setLocal(() => isLoading = true);
            final result = await _service.extendBorrow(
              row.borrowId,
              ExtendRequest(newDueDate: newDueDate!),
              currentDueDate: row.dueDate,
            );
            setLocal(() => isLoading = false);
            if (result.isSuccess) {
              _closeModal();
              _toast(
                  'Gia hạn thành công! Hạn mới: ${_dateFormat.format(result.data!.newDueDate)}');
              _loadData();
            } else {
              _toast(result.errorMessage!, error: true);
            }
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: _DetailRow(
                  'Hạn hiện tại',
                  _dateFormat.format(row.dueDate),
                  highlight: true,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ngày gia hạn mới *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: TextField(
                      controller: dueDateCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              row.dueDate.add(const Duration(days: 7)),
                          firstDate:
                              row.dueDate.add(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setLocal(() {
                            newDueDate = picked;
                            dueDateCtrl.text = _dateFormat.format(picked);
                          });
                        }
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Chọn ngày gia hạn mới',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBFC4CC),
                        ),
                        suffixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
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
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  // ── 5. Xác nhận báo mất ───────────────────

  // ── 6. Huỷ phiếu mượn ────────────────────

  void _confirmCancelBorrow(BorrowSummaryView row) {
    _openModal((ctrl) => AppModal(
      controller: ctrl,
      width: 440,
      header: AppModalHeader(
        icon: Icons.cancel_outlined,
        iconColor: const Color(0xFFEF4444),
        iconBg: const Color(0xFFFEF2F2),
        title: 'Huỷ phiếu mượn',
        subtitle: 'Phiếu: ${row.borrowId}',
        onClose: _closeModal,
      ),
      footer: AppModalFooter(
        onCancel: _closeModal,
        confirmLabel: 'Xác nhận huỷ',
        showRequiredHint: false,
        onConfirm: () async {
          final result = await _service.cancelBorrow(row.borrowId);
          _closeModal();
          if (result.isSuccess) {
            _toast('Đã huỷ phiếu mượn thành công');
            _loadData();
          } else {
            _toast(result.errorMessage!, error: true);
          }
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Huỷ phiếu mượn "${row.bookTitle}" của ${row.readerName}? Hành động này có thể hoàn tác.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ── 7. Hoàn tác huỷ phiếu ─────────────────

  void _confirmUndoCancel(BorrowSummaryView row) {
    _openModal((ctrl) => AppModal(
      controller: ctrl,
      width: 440,
      header: AppModalHeader(
        icon: Icons.undo_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBg: const Color(0xFFEFF6FF),
        title: 'Hoàn tác huỷ phiếu',
        subtitle: 'Phiếu: ${row.borrowId}',
        onClose: _closeModal,
      ),
      footer: AppModalFooter(
        onCancel: _closeModal,
        confirmLabel: 'Hoàn tác',
        showRequiredHint: false,
        onConfirm: () async {
          final result = await _service.undoCancelBorrow(row.borrowId);
          _closeModal();
          if (result.isSuccess) {
            _toast('Đã hoàn tác huỷ phiếu thành công');
            _loadData();
          } else {
            _toast(result.errorMessage!, error: true);
          }
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF2563EB), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Khôi phục phiếu mượn "${row.bookTitle}" của ${row.readerName} về trạng thái Đang mượn?',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ── 8. Sửa phiếu mượn ─────────────────────

  void _openEditModal(BorrowSummaryView row) {
    // Khởi tạo state từ data hiện tại của row
    BookCondition condition      = BookCondition.GOOD;
    bool          isLoading      = false;

    String? selectedReaderId     = row.bookId.isNotEmpty ? row.bookId : null;
    String  selectedReaderName   = row.readerName;
    String? selectedBookId       = row.bookId;
    String  selectedBookName     = row.bookTitle.isNotEmpty ? row.bookTitle : row.bookId;

    // Date controllers — pre-fill từ row
    final borrowDateCtrl = TextEditingController(
        text: _dateFormat.format(row.borrowDate));
    final dueDateCtrl    = TextEditingController(
        text: _dateFormat.format(row.dueDate));
    DateTime borrowDate  = row.borrowDate;
    DateTime dueDate     = row.dueDate;

    _openModal((ctrl) => StatefulBuilder(
      builder: (ctx, setLocal) => AppModal(
        controller: ctrl,
        width: 560,
        header: AppModalHeader(
          icon: Icons.edit_outlined,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFFEFF6FF),
          title: 'Sửa phiếu mượn',
          subtitle: 'Phiếu: ${row.borrowId}',
          onClose: _closeModal,
        ),
        footer: AppModalFooter(
          onCancel: _closeModal,
          confirmLabel: 'Lưu thay đổi',
          confirmIcon: Icons.save_outlined,
          isLoading: isLoading,
          onConfirm: () async {
            if (selectedBookId == null) {
              _toast('Vui lòng chọn sách', error: true);
              return;
            }
            setLocal(() => isLoading = true);
            final result = await _service.updateBorrow(
              row.borrowId,
              UpdateBorrowRequest(
                bookId:          selectedBookId,
                readerId:        selectedReaderId,
                borrowDate:      borrowDate,
                dueDate:         dueDate,
                conditionBorrow: condition,
              ),
            );
            setLocal(() => isLoading = false);
            if (result.isSuccess) {
              _closeModal();
              _toast('Cập nhật phiếu mượn thành công');
              _loadData();
            } else {
              _toast(result.errorMessage!, error: true);
            }
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mã phiếu (read-only)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.receipt_outlined,
                        size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 8),
                    Text('Mã phiếu: ${row.borrowId}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Độc giả ──────────────────────────
                _SearchSelectField(
                  label: 'Tên độc giả *',
                  hint: 'Tìm và chọn độc giả...',
                  selectedName: selectedReaderName.isNotEmpty
                      ? selectedReaderName
                      : null,
                  icon: Icons.person_outline_rounded,
                  fetchItems: () async {
                    try {
                      final res = await AppGateway.instance.reader
                          .get('/readers');
                      final list = res.asList();
                      return list.map((e) => _SelectItem(
                        id:       (e['id'] ?? e['readerId'] ?? '').toString(),
                        name:     (e['name'] ?? e['fullName'] ?? '').toString(),
                        subtitle: (e['email'] ?? '').toString(),
                      )).where((i) => i.id.isNotEmpty).toList();
                    } catch (_) { return []; }
                  },
                  onSelected: (item) => setLocal(() {
                    selectedReaderId   = item.id;
                    selectedReaderName = item.name;
                  }),
                  onCleared: () => setLocal(() {
                    selectedReaderId   = null;
                    selectedReaderName = '';
                  }),
                ),
                const SizedBox(height: 16),

                // ── Sách ─────────────────────────────
                _SearchSelectField(
                  label: 'Tên sách *',
                  hint: 'Tìm và chọn sách...',
                  selectedName: selectedBookName.isNotEmpty
                      ? selectedBookName
                      : null,
                  icon: Icons.menu_book_outlined,
                  fetchItems: () async {
                    final result = await _bookService.fetchBooks();
                    if (result case Success(:final data)) {
                      return data.map((b) => _SelectItem(
                        id:       b.id,
                        name:     b.title,
                        subtitle: b.author,
                        extra:    b.availableStock > 0
                                      ? 'Còn ${b.availableStock}'
                                      : 'Hết hàng',
                        extraOk:  b.availableStock > 0,
                      )).toList();
                    }
                    return [];
                  },
                  onSelected: (item) => setLocal(() {
                    selectedBookId   = item.id;
                    selectedBookName = item.name;
                  }),
                  onCleared: () => setLocal(() {
                    selectedBookId   = null;
                    selectedBookName = '';
                  }),
                ),
                const SizedBox(height: 16),

                // ── Ngày mượn + Hạn trả ──────────────
                Row(children: [
                  Expanded(
                    child: AppModalField(
                      label: 'Ngày mượn',
                      controller: borrowDateCtrl,
                      hint: 'dd/MM/yyyy',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.calendar_today_rounded,
                          size: 15, color: Color(0xFF9CA3AF)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: borrowDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setLocal(() {
                            borrowDate = picked;
                            borrowDateCtrl.text =
                                _dateFormat.format(picked);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppModalField(
                      label: 'Hạn trả',
                      controller: dueDateCtrl,
                      hint: 'dd/MM/yyyy',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.calendar_today_rounded,
                          size: 15, color: Color(0xFF9CA3AF)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setLocal(() {
                            dueDate = picked;
                            dueDateCtrl.text =
                                _dateFormat.format(picked);
                          });
                        }
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Tình trạng sách ───────────────────
                _ConditionDropdown(
                  label: 'Tình trạng sách khi mượn',
                  value: condition,
                  onChanged: (v) => setLocal(() => condition = v),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

// ─────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────


// ── Toggle option (Trả sách / Báo mất) ────────────────────

// ── _PreviewRow — hàng label/value trong preview card ──────

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value,
      {this.bold = false, this.valueColor});
  final String label;
  final String value;
  final bool   bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ??
                    (bold ? const Color(0xFF111827) : const Color(0xFF374151)),
              )),
        ],
      ),
    );
  }
}




class _ToggleOption extends StatefulWidget {
  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  @override
  State<_ToggleOption> createState() => _ToggleOptionState();
}

class _ToggleOptionState extends State<_ToggleOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.color.withOpacity(0.08)
                : _hovered
                    ? const Color(0xFFF9FAFB)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected
                  ? widget.color
                  : const Color(0xFFE5E7EB),
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 16,
                  color: widget.selected
                      ? widget.color
                      : const Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.selected
                      ? widget.color
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────

class _BorrowStatusBadge extends StatelessWidget {
  final BorrowStatus status;
  const _BorrowStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      BorrowStatus.BORROWED  => ('Đang mượn', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
      BorrowStatus.RETURNED  => ('Đã trả',    const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
      BorrowStatus.OVERDUE   => ('Quá hạn',   const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
      BorrowStatus.LOST      => ('Mất sách',  const Color(0xFFFFFBEB), const Color(0xFFD97706)),
      BorrowStatus.CANCELLED => ('Đã huỷ',   const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _SelectItem — item trong danh sách search-select
// ─────────────────────────────────────────────

class _SelectItem {
  final String  id;
  final String  name;
  final String? subtitle;
  final String? extra;
  final bool    extraOk;

  const _SelectItem({
    required this.id,
    required this.name,
    this.subtitle,
    this.extra,
    this.extraOk = true,
  });
}

// ─────────────────────────────────────────────
//  _SearchSelectField — ô bấm mở overlay tìm kiếm
// ─────────────────────────────────────────────

class _SearchSelectField extends StatefulWidget {
  const _SearchSelectField({
    required this.label,
    required this.hint,
    required this.fetchItems,
    required this.onSelected,
    required this.onCleared,
    this.selectedName,
    this.icon,
  });

  final String                          label;
  final String                          hint;
  final String?                         selectedName;
  final IconData?                       icon;
  final Future<List<_SelectItem>> Function() fetchItems;
  final ValueChanged<_SelectItem>       onSelected;
  final VoidCallback                    onCleared;

  @override
  State<_SearchSelectField> createState() => _SearchSelectFieldState();
}

class _SearchSelectFieldState extends State<_SearchSelectField>
    with SingleTickerProviderStateMixin {
  OverlayEntry?            _overlay;
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _removeOverlay(); _ctrl.dispose(); super.dispose(); }

  void _removeOverlay() { _overlay?.remove(); _overlay = null; }

  Future<void> _close() async { await _ctrl.reverse(); _removeOverlay(); }

  void _open() {
    if (_overlay != null) { _close(); return; }

    final box   = _key.currentContext!.findRenderObject() as RenderBox;
    final pos   = box.localToGlobal(Offset.zero);
    final size  = box.size;

    _overlay = OverlayEntry(builder: (_) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _close,
      child: Stack(children: [
        Positioned(
          left:  pos.dx,
          top:   pos.dy + size.height + 4,
          width: size.width,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: _SearchSelectOverlay(
                  fetchItems: widget.fetchItems,
                  onSelect: (item) {
                    widget.onSelected(item);
                    _close();
                    setState(() {});
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.selectedName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        GestureDetector(
          key: _key,
          onTap: _open,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: hasValue
                  ? const Color(0xFFF0F4FF)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _overlay != null
                    ? const Color(0xFF2563EB)
                    : hasValue
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFFE5E7EB),
                width: _overlay != null ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16,
                    color: hasValue
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  hasValue ? widget.selectedName! : widget.hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasValue
                        ? const Color(0xFF111827)
                        : const Color(0xFFD1D5DB),
                    fontWeight: hasValue
                        ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (hasValue)
                GestureDetector(
                  onTap: () {
                    widget.onCleared();
                    _removeOverlay();
                    setState(() {});
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF9CA3AF)),
                )
              else
                AnimatedRotation(
                  turns: _overlay != null ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Color(0xFF9CA3AF)),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Overlay content ───────────────────────────

class _SearchSelectOverlay extends StatefulWidget {
  const _SearchSelectOverlay({
    required this.fetchItems,
    required this.onSelect,
  });
  final Future<List<_SelectItem>> Function() fetchItems;
  final ValueChanged<_SelectItem> onSelect;

  @override
  State<_SearchSelectOverlay> createState() => _SearchSelectOverlayState();
}

class _SearchSelectOverlayState extends State<_SearchSelectOverlay> {
  final _ctrl  = TextEditingController();
  List<_SelectItem> _all      = [];
  List<_SelectItem> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(_filter);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final items = await widget.fetchItems();
    if (!mounted) return;
    setState(() { _all = items; _filtered = items; _loading = false; });
  }

  void _filter() {
    final q = _ctrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((i) =>
              i.name.toLowerCase().contains(q) ||
              (i.subtitle?.toLowerCase().contains(q) ?? false) ||
              i.id.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10),
              blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBFC4CC)),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search_rounded, size: 16,
                      color: Color(0xFF9CA3AF)),
                ),
                prefixIconConstraints: const BoxConstraints(),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // List
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                : _filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Không tìm thấy',
                            style: TextStyle(fontSize: 13,
                                color: Color(0xFF9CA3AF)))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onSelect(item),
                              hoverColor: const Color(0xFFF5F7FA),
                              splashColor: Colors.transparent,
                              highlightColor: const Color(0xFFEEF0F3),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(children: [
                                  Expanded(child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF111827))),
                                      if (item.subtitle != null &&
                                          item.subtitle!.isNotEmpty)
                                        Text(item.subtitle!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9CA3AF))),
                                    ],
                                  )),
                                  if (item.extra != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item.extraOk
                                            ? const Color(0xFFF0FDF4)
                                            : const Color(0xFFFEF2F2),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(item.extra!,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: item.extraOk
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFDC2626))),
                                    ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Detail card helpers
// ─────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children, this.title, this.icon});
  final List<Widget> children;
  final String?  title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                  ],
                  Text(title!,
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.4)),
                ]),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow(this.label, this.value, {
    this.icon, this.iconColor, this.valueColor});
  final String  label;
  final String  value;
  final IconData? icon;
  final Color?  iconColor;
  final Color?  valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 14,
            color: iconColor ?? const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
      ],
      SizedBox(width: 80,
          child: Text(label, style: const TextStyle(
              fontSize: 12, color: Color(0xFF9CA3AF)))),
      Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: valueColor ?? const Color(0xFF111827))),
    ]);
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label,
      this.value, this.valueWidget, this.valueColor});
  final String  label;
  final String? value;
  final Widget? valueWidget;
  final Color?  valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          fontSize: 11, color: Color(0xFF9CA3AF))),
      const SizedBox(height: 4),
      valueWidget ?? Text(value ?? '',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827))),
    ]);
  }
}

// ── Detail row ─────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Widget? valueWidget;
  final VoidCallback? onTap;

  const _DetailRow(
    this.label,
    this.value, {
    this.highlight = false,
    Widget? valueWidget,
    VoidCallback? onTap,
  }) : valueWidget = valueWidget, onTap = onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: valueWidget ??
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onTap != null
                          ? const Color(0xFF2563EB)
                          : highlight
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF111827),
                      decoration: onTap != null
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Condition dropdown ─────────────────────

class _ConditionDropdown extends StatelessWidget {
  final String label;
  final BookCondition value;
  final ValueChanged<BookCondition> onChanged;

  const _ConditionDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _items = [
    AppDropdownItem(
      value: BookCondition.NEW,
      label: 'Mới',
      dotColor: Color(0xFF16A34A),
    ),
    AppDropdownItem(
      value: BookCondition.GOOD,
      label: 'Tốt',
      dotColor: Color(0xFF2563EB),
    ),
    AppDropdownItem(
      value: BookCondition.WORN,
      label: 'Cũ',
      dotColor: Color(0xFFD97706),
    ),
    AppDropdownItem(
      value: BookCondition.DAMAGED,
      label: 'Hư hỏng',
      dotColor: Color(0xFFDC2626),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppDropdown<BookCondition>(
      label: label,
      value: value,
      hint: 'Chọn tình trạng...',
      items: _items,
      icon: Icons.bookmark_outline_rounded,
      onChanged: onChanged,
    );
  }
}

// ── Small action icon button ───────────────

class _ActionIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  State<_ActionIconBtn> createState() => _ActionIconBtnState();
}

class _ActionIconBtnState extends State<_ActionIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _BookDetailDialog
//
//  Modal xem chi tiết sách mở từ bên trong modal phiếu mượn.
//  Dùng AnimationController RIÊNG — hoàn toàn độc lập với
//  _modalCtrl của BorrowPage — để đóng/mở không ảnh hưởng
//  animation của modal cha phía dưới.
// ─────────────────────────────────────────────────────────────

class _BookDetailDialog extends StatefulWidget {
  const _BookDetailDialog({required this.data});
  final BookDetail data;

  @override
  State<_BookDetailDialog> createState() => _BookDetailDialogState();
}

class _BookDetailDialogState extends State<_BookDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    // Stock status
    final (statusLabel, statusFg, statusBg) = d.availableStock == 0
        ? ('Hết hàng', const Color(0xFFDC2626), const Color(0xFFFEF2F2))
        : d.availableStock <= 3
            ? ('Sắp hết',  const Color(0xFFD97706), const Color(0xFFFFFBEB))
            : ('Còn sách', const Color(0xFF16A34A), const Color(0xFFF0FDF4));

    return AppModal(
      controller: _ctrl,
      width: 560,
      header: AppModalHeader(
        icon:      Icons.menu_book_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg:    const Color(0xFFF5F3FF),
        title:     d.title,
        subtitle:  d.author,
        onClose:   _close,
      ),
      footer: AppModalFooter(
        onCancel:         _close,
        onConfirm:        _close,
        confirmLabel:     'Đóng',
        cancelLabel:      '',
        showRequiredHint: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Card: Thông tin cơ bản ──────────────────────
            _BdCard(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book icon
                    Container(
                      width: 48, height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFDDD6FE), width: 1),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          size: 22, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 14),
                    // Title + author + meta
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                height: 1.3)),
                        const SizedBox(height: 3),
                        Text(d.author,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280))),
                        const SizedBox(height: 8),
                        // Meta row
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          _BdMeta(
                            icon: Icons.calendar_today_outlined,
                            label: '${d.publicationYear}',
                          ),
                          if (d.shelfLocation != null)
                            _BdMeta(
                              icon: Icons.shelves,
                              label: d.shelfLocation!,
                            ),
                          if (d.isbn != null)
                            _BdMeta(
                              icon: Icons.tag_rounded,
                              label: d.isbn!,
                            ),
                        ]),
                      ],
                    )),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusFg)),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Card: Kho sách ──────────────────────────────
            _BdCard(
              label: 'Kho sách',
              icon:  Icons.inventory_2_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(children: [
                    _BdStockChip(
                      label: 'Tổng',
                      value: d.totalStock,
                      color: const Color(0xFF2563EB),
                      bg:    const Color(0xFFEFF6FF),
                    ),
                    const SizedBox(width: 8),
                    _BdStockChip(
                      label: 'Khả dụng',
                      value: d.availableStock,
                      color: statusFg,
                      bg:    statusBg,
                    ),
                    const SizedBox(width: 8),
                    _BdStockChip(
                      label: 'Đang mượn',
                      value: d.lentOutCount,
                      color: const Color(0xFFD97706),
                      bg:    const Color(0xFFFFFBEB),
                    ),
                  ]),
                ),
              ],
            ),

            // ── Card: Thể loại ──────────────────────────────
            if (d.genres.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BdCard(
                label: 'Thể loại',
                icon:  Icons.label_outline_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: d.genres.map((g) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFDDD6FE)),
                        ),
                        child: Text(g,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7C3AED))),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ],

            // ── Card: Mô tả ─────────────────────────────────
            if (d.description != null && d.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BdCard(
                label: 'Mô tả',
                icon:  Icons.notes_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Text(
                      d.description!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.6),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── _BdCard — card container dùng trong _BookDetailDialog ─────

class _BdCard extends StatelessWidget {
  const _BdCard({required this.children, this.label, this.icon});
  final List<Widget> children;
  final String?   label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                  ],
                  Text(label!,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.4)),
                ]),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── _BdMeta — chip meta nhỏ (năm, kệ, isbn) ──────────────────

class _BdMeta extends StatelessWidget {
  const _BdMeta({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── _BdStockChip — ô kho số liệu ─────────────────────────────

class _BdStockChip extends StatelessWidget {
  const _BdStockChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });
  final String label;
  final int    value;
  final Color  color;
  final Color  bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }
}
// ─────────────────────────────────────────────
//  _PaymentBadge — trạng thái thanh toán
// ─────────────────────────────────────────────

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      PaymentStatus.PAID   => ('Đã thanh toán', const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      PaymentStatus.UNPAID => ('Chưa thanh toán', const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
      PaymentStatus.NONE   => ('Không áp dụng', const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

// ─────────────────────────────────────────────
//  _PayFineButton — nút thanh toán trong card
// ─────────────────────────────────────────────

class _PayFineButton extends StatelessWidget {
  const _PayFineButton({
    required this.fine,
    required this.onTap,
    this.isLoading = false,
  });
  final double       fine;
  final VoidCallback onTap;
  final bool         isLoading;

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: 42,
        decoration: BoxDecoration(
          color: isLoading ? const Color(0xFFFECACA) : const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              const Icon(Icons.payment_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isLoading ? 'Đang xử lý...' : 'Thanh toán ${_fmt(fine)} đ',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _PayFineConfirmDialog — xác nhận thanh toán
// ─────────────────────────────────────────────

class _PayFineConfirmDialog extends StatefulWidget {
  const _PayFineConfirmDialog({
    required this.borrowId,
    required this.bookTitle,
    required this.fine,
  });
  final String borrowId;
  final String bookTitle;
  final double fine;

  @override
  State<_PayFineConfirmDialog> createState() => _PayFineConfirmDialogState();
}

class _PayFineConfirmDialogState extends State<_PayFineConfirmDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _close([bool result = false]) async {
    await _ctrl.reverse();
    if (mounted) Navigator.pop(context, result);
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.center,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 60),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 32, offset: Offset(0, 12))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                  child: Column(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.payment_rounded, size: 28, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Xác nhận thanh toán phạt',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 8),
                    Text(widget.bookTitle,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(children: [
                        const Text('Số tiền phạt', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 4),
                        Text('${_fmt(widget.fine)} đ',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                      ]),
                    ),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(child: _ConfirmBtn(label: 'Huỷ', filled: false, onTap: () => _close(false))),
                    const SizedBox(width: 10),
                    Expanded(child: _ConfirmBtn(label: 'Xác nhận thanh toán', filled: true, onTap: () => _close(true))),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _ConfirmBtn ────────────────────────────────

class _ConfirmBtn extends StatefulWidget {
  const _ConfirmBtn({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool   filled;
  final VoidCallback onTap;

  @override
  State<_ConfirmBtn> createState() => _ConfirmBtnState();
}

class _ConfirmBtnState extends State<_ConfirmBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg     = widget.filled ? (_pressed ? const Color(0xFFB91C1C) : const Color(0xFFDC2626)) : (_pressed ? const Color(0xFFF3F4F6) : Colors.white);
    final border = widget.filled ? Colors.transparent : const Color(0xFFE5E7EB);
    final text   = widget.filled ? Colors.white : const Color(0xFF374151);
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Text(widget.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text)),
      ),
    );
  }
}