import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_table.dart';
import '../widgets/custom_button.dart' hide TableActions;
import '../widgets/custom_modal.dart';
import '../widgets/custom_filter.dart';

// ─────────────────────────────────────────────────────────────
//  BooksPage
// ─────────────────────────────────────────────────────────────

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  late final BookService _service;

  List<BookSummary> _books    = [];
  List<BookSummary> _filtered = [];
  bool              _isLoading   = true;
  String?           _error;
  String            _searchText  = '';
  String?           _activeGenre;
  String?           _activeStatus;

  int get _totalTitles => _books.length;
  int get _totalStock  => _books.fold(0, (s, b) => s + b.totalStock);
  int get _totalAvail  => _books.fold(0, (s, b) => s + b.availableStock);
  int get _totalLent   => _books.fold(0, (s, b) => s + b.lentOutCount);
  int get _outOfStock  => _books.where((b) => b.availableStock == 0).length;

  List<String> get _searchSuggestions => {
        ..._books.map((b) => b.title),
        ..._books.map((b) => b.author),
      }.toList()..sort();

  @override
  @override
  void initState() {
    super.initState();
    _service = BookService();   
    _loadBooks();
  }

  // ─────────────────────────────────────────────────────────────
  //  Data
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadBooks() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _service.fetchBooks();
    setState(() {
      _isLoading = false;
      switch (result) {
        case Success(:final data):
          _books = data;
          _applyFilter();
        case Failure(:final message):
          _error = message;
      }
    });
  }

  String _bookStatus(BookSummary b) {
    if (b.availableStock == 0) return 'out';
    if (b.availableStock <= 3) return 'low';
    return 'ok';
  }

  void _applyFilter() {
    final q = _searchText.toLowerCase();
    _filtered = _books.where((b) {
      final matchSearch = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q);
      final matchGenre  = _activeGenre  == null || b.genres.contains(_activeGenre);
      final matchStatus = _activeStatus == null || _bookStatus(b) == _activeStatus;
      return matchSearch && matchGenre && matchStatus;
    }).toList();
  }

  void _onSearch(String v)       => setState(() { _searchText = v;  _applyFilter(); });
  void _onGenreFilter(String? g) => setState(() {
        _activeGenre = (_activeGenre == g) ? null : g; _applyFilter();
      });
  void _onStatusFilter(String? s) => setState(() {
        _activeStatus = (_activeStatus == s) ? null : s; _applyFilter();
      });

  // ─────────────────────────────────────────────────────────────
  //  Delete
  // ─────────────────────────────────────────────────────────────

  Future<void> _deleteBook(BookSummary book) async {
    final confirm = await showDialog<bool>(
          context: context,
          barrierColor: const Color(0x80000000),
          builder: (_) => _DeleteConfirmDialog(book: book),
        ) ??
        false;
    if (!confirm || !mounted) return;

    final result = await _service.deleteBook(book.id);
    if (!mounted) return;

    switch (result) {
      case Success():
        setState(() {
          _books.removeWhere((b) => b.id == book.id);
          _applyFilter();
        });
        _showSnackBar('Đã xoá "${book.title}"', isError: false);
      case Failure(:final message):
        _showSnackBar(message, isError: true);
    }
  }

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
  //  Navigation
  // ─────────────────────────────────────────────────────────────

  Future<void> _goToDetail(BookSummary book) async {
    final detailResult = await _service.fetchBookById(book.id);
    if (!mounted) return;

    switch (detailResult) {
      case Success(:final data):
        await showDialog<void>(
          context: context,
          barrierColor: const Color(0x80000000),
          builder: (_) => BookDetailModal(detail: data),
        );
      case Failure(:final message):
        _showSnackBar(message, isError: true);
    }
  }

  Future<void> _goToEdit(BookSummary book) async {
    // Fetch full detail để có description, isbn, shelfLocation
    final detailResult = await _service.fetchBookById(book.id);
    if (!mounted) return;

    final BookDetail detail;
    switch (detailResult) {
      case Success(:final data):
        detail = data;
      case Failure(:final message):
        _showSnackBar(message, isError: true);
        return;
    }

    final updated = await showDialog<BookDetail>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => EditBookModal(service: _service, detail: detail),
    );
    if (updated == null || !mounted) return;
    await _loadBooks();
    _showSnackBar('Đã cập nhật "${updated.title}"', isError: false);
  }

  Future<void> _goToCreate() async {
    final created = await showDialog<BookDetail>(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (_) => AddBookModal(service: _service),
    );
    if (created == null || !mounted) return;
    await _loadBooks();
    _showSnackBar('Đã thêm "${created.title}"', isError: false);
  }

  Future<void> _goToStock(BookSummary book) async {
    final detailResult = await _service.fetchBookById(book.id);
    if (!mounted) return;

    switch (detailResult) {
      case Success(:final data):
        await showDialog<void>(
          context: context,
          barrierColor: const Color(0x80000000),
          builder: (_) => StockUpdateModal(
              service: _service, detail: data),
        );
        await _loadBooks();
      case Failure(:final message):
        _showSnackBar(message, isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Table columns
  // ─────────────────────────────────────────────────────────────

  List<AppTableColumn<BookSummary>> get _columns => [
        AppTableColumn(
          label: 'Tiêu đề / Tác giả',
          flex: 3,
          sortable: true,
          sortKey: 'title',
          builder: (b) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(b.title,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(b.author,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        AppTableColumn(
          label: 'Thể loại',
          flex: 2,
          builder: (b) => Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...b.genres.take(2).map((g) =>
                    _GenreChip(label: BookGenres.all[g] ?? g)),
              if (b.genres.length > 2)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('+${b.genres.length - 2}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280))),
                ),
            ],
          ),
        ),
        AppTableColumn(
          label: 'Năm',
          flex: 1,
          sortable: true,
          sortKey: 'year',
          builder: (b) => Text('${b.publicationYear}',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280))),
        ),
        AppTableColumn(
          label: 'Tồn kho',
          flex: 1,
          sortable: true,
          sortKey: 'stock',
          builder: (b) => RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: '${b.availableStock}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
              TextSpan(
                  text: ' / ${b.totalStock}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFD1D5DB))),
            ]),
          ),
        ),
        AppTableColumn(
          label: 'Trạng thái',
          flex: 1,
          builder: (b) => _StatusBadge(status: _bookStatus(b)),
        ),
        AppTableColumn(
          label: 'Thao tác',
          fixedWidth: 160,
          builder: (b) => TableActions(
            onView:   () => _goToDetail(b),
            onEdit:   () => _goToEdit(b),
            onDelete: () => _deleteBook(b),
            onStock:  () => _goToStock(b),
          ),
        ),
      ];

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
              label: 'Thử lại',
              icon: Icons.refresh_rounded,
              onPressed: _loadBooks),
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
          // Header
          Row(children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quản lý sách',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827))),
                  SizedBox(height: 4),
                  Text('Danh sách toàn bộ đầu sách trong thư viện',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            AppButton(
                label: 'Thêm sách',
                icon: Icons.add_rounded,
                onPressed: _goToCreate),
          ]),

          const SizedBox(height: 24),

          // Stats
          Row(children: [
            Expanded(child: StatCard(
              icon: Icons.menu_book_rounded,
              title: 'Tổng đầu sách',
              value: _totalTitles,
              color: const Color(0xFF2563EB),
              subtitle: 'Trong thư viện',
            )),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              icon: Icons.library_books_rounded,
              title: 'Tổng bản sách',
              value: _totalStock,
              color: const Color(0xFF7C3AED),
              subtitle: 'Tất cả bản in',
            )),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              icon: Icons.check_circle_outline_rounded,
              title: 'Sách khả dụng',
              value: _totalAvail,
              color: const Color(0xFF16A34A),
              subtitle: 'Sẵn sàng cho mượn',
            )),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              icon: Icons.swap_horiz_rounded,
              title: 'Đã cho mượn',
              value: _totalLent,
              color: const Color(0xFFF59E0B),
              subtitle: 'Đang ngoài thư viện',
            )),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              icon: Icons.do_not_disturb_alt_rounded,
              title: 'Hết hàng',
              value: _outOfStock,
              color: const Color(0xFFEF4444),
              subtitle: 'Cần nhập thêm',
              onTap: () => _onStatusFilter('out'),
            )),
          ]),

          const SizedBox(height: 24),

          // Toolbar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: SearchBarWidget(
                  hintText: 'Tìm theo tiêu đề hoặc tác giả...',
                  suggestions: _searchSuggestions,
                  onChanged: _onSearch,
                  onSelect: _onSearch,
                ),
              ),
              const SizedBox(width: 12),
              FilterPopup(
                label: 'Trạng thái',
                selected: _activeStatus,
                searchable: false,
                items: const {
                  'ok':  'Còn sách',
                  'low': 'Sắp hết',
                  'out': 'Hết hàng',
                },
                onChanged: _onStatusFilter,
              ),
              const SizedBox(width: 10),
              FilterPopup(
                label: 'Thể loại',
                selected: _activeGenre,
                searchable: true,
                items: BookGenres.all,
                onChanged: _onGenreFilter,
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: Icons.refresh_rounded,
                onPressed: _loadBooks,
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
                  : 'Hiển thị ${_filtered.length} / $_totalTitles đầu sách',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFD1D5DB)),
            ),
          ),

          AppTable<BookSummary>(
            rows: _filtered,
            columns: _columns,
            cellValue: (b, key) => switch (key) {
              'title' => b.title,
              'year'  => b.publicationYear,
              'stock' => b.availableStock,
              _       => '',
            },
            emptyMessage: _searchText.isNotEmpty
                ? 'Không tìm thấy sách phù hợp với "$_searchText"'
                : 'Chưa có sách nào trong thư viện',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BookGenres — single source of truth cho tất cả genre
// ─────────────────────────────────────────────────────────────

class BookGenres {
  BookGenres._();

  static const Map<String, String> all = {
    'anthology':            'Anthology',
    'art_music':            'Art & Music',
    'audience_adult':       'Adult',
    'audience_childrens':   "Children's",
    'audience_juvenile':    'Juvenile',
    'audience_young_adult': 'Young Adult',
    'biography_memoir':     'Biography & Memoir',
    'business':             'Business',
    'classic':              'Classic',
    'comics_graphic_novels':'Comics & Graphic Novels',
    'cooking':              'Cooking',
    'drama':                'Drama',
    'essay':                'Essay',
    'fantasy':              'Fantasy',
    'historical_fiction':   'Historical Fiction',
    'history':              'History',
    'horror':               'Horror',
    'literary_fiction':     'Literary Fiction',
    'philosophy':           'Philosophy',
    'poetry':               'Poetry',
    'politics':             'Politics',
    'religion':             'Religion',
    'romance':              'Romance',
    'science':              'Science',
    'science_fiction':      'Science Fiction',
    'self_help':            'Self Help',
    'sports':               'Sports',
    'technology':           'Technology',
    'thriller':             'Thriller',
    'travel':               'Travel',
    'type_fiction':         'Fiction',
    'type_nonfiction':      'Non-fiction',
    'western':              'Western',
  };

  /// Normalize genre string từ API về key chuẩn trong [all].
  static String? normalize(String raw) {
    String _strip(String s) =>
        s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
         .replaceAll(RegExp(r' +'), ' ')
         .trim();

    final reverseMap = <String, String>{
      // key → key
      ...{for (final e in all.entries) e.key: e.key},
      // display value lowercase (e.g. "self help" → "self_help")
      ...{for (final e in all.entries) e.value.toLowerCase(): e.key},
      // key với _ → space
      ...{for (final e in all.entries) e.key.replaceAll('_', ' '): e.key},
      // display bỏ hyphen ("non-fiction" → "nonfiction")
      ...{for (final e in all.entries)
        e.value.toLowerCase().replaceAll('-', ''): e.key},
      // display stripped ký tự đặc biệt ("comics & graphic novels" → "comics  graphic novels")
      ...{for (final e in all.entries) _strip(e.value.toLowerCase()): e.key},
      // stripped + underscore
      ...{for (final e in all.entries)
        _strip(e.value.toLowerCase()).replaceAll(' ', '_'): e.key},
    };

    final n = raw.trim().toLowerCase();
    if (reverseMap.containsKey(n)) return reverseMap[n];

    // Thử đổi hyphen → space / underscore / bỏ luôn
    final noHyphenSpace = n.replaceAll('-', ' ');
    final noHyphenUnder = n.replaceAll('-', '_');
    final noHyphenGlue  = n.replaceAll('-', '');

    if (reverseMap.containsKey(noHyphenSpace)) return reverseMap[noHyphenSpace];
    if (reverseMap.containsKey(noHyphenUnder))  return reverseMap[noHyphenUnder];
    if (reverseMap.containsKey(noHyphenGlue))   return reverseMap[noHyphenGlue];

    // Thử thêm: bỏ ký tự đặc biệt & , ; để match "comics & graphic novels"
    final stripped = n.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
                      .replaceAll(RegExp(r' +'), ' ')
                      .trim();
    return reverseMap[stripped] ??
        reverseMap[stripped.replaceAll(' ', '_')];
  }
}

// ─────────────────────────────────────────────────────────────
//  _StatusBadge
// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, textColor, bgColor) = switch (status) {
      'out' => (
          'Hết hàng',
          const Color(0xFFA32D2D),
          const Color(0xFFFCEBEB),
        ),
      'low' => (
          'Sắp hết',
          const Color(0xFF854F0B),
          const Color(0xFFFAEEDA),
        ),
      _ => (
          'Còn sách',
          const Color(0xFF3B6D11),
          const Color(0xFFEAF3DE),
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textColor)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _GenreChip
// ─────────────────────────────────────────────────────────────

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});
  final String label;

  static const _bgColors = [
    Color(0xFFEFF6FF), Color(0xFFF0FDF4), Color(0xFFFEF9C3),
    Color(0xFFFDF2F8), Color(0xFFF0F4FF),
  ];
  static const _textColors = [
    Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFFCA8A04),
    Color(0xFF9333EA), Color(0xFF4F46E5),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = label.hashCode.abs() % _bgColors.length;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _bgColors[idx],
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _textColors[idx])),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _GenreSelectorSection — dùng chung giữa Add và Edit modal
// ─────────────────────────────────────────────────────────────

class _GenreSelectorSection extends StatefulWidget {
  const _GenreSelectorSection({
    required this.service,
    required this.selectedGenres,
    required this.onChanged,
    required this.titleCtrl,
    required this.descCtrl,
    this.submitError,
    this.onErrorClear,
  });

  final BookService              service;
  final List<String>             selectedGenres;
  final ValueChanged<List<String>> onChanged;
  final TextEditingController    titleCtrl;
  final TextEditingController    descCtrl;
  final String?                  submitError;
  final VoidCallback?            onErrorClear;

  @override
  State<_GenreSelectorSection> createState() =>
      _GenreSelectorSectionState();
}

class _GenreSelectorSectionState
    extends State<_GenreSelectorSection> {
  // Giữ cả key chuẩn + confidence để hiển thị %
  List<({String key, double confidence})> _predictions = [];
  bool _isPredicting = false;

  Future<void> _predictGenre() async {
    if (widget.titleCtrl.text.trim().isEmpty &&
        widget.descCtrl.text.trim().isEmpty) return;

    setState(() { _isPredicting = true; _predictions = []; });

    final result = await widget.service.predictGenre(
      title:       widget.titleCtrl.text.trim(),
      description: widget.descCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isPredicting = false;
      if (result case Success(:final data)) {
        // Normalize key, loại trùng đã chọn, sắp xếp confidence giảm dần
        final seen = <String>{};
        _predictions = data.predictions
            .map((p) {
              final key = BookGenres.normalize(p.genre) ?? '';
              return (key: key, confidence: p.confidence);
            })
            .where((p) => p.key.isNotEmpty)
            .where((p) => BookGenres.all.containsKey(p.key))
            .where((p) => !widget.selectedGenres.contains(p.key))
            .where((p) => seen.add(p.key)) // loại trùng key
            .toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
      }
    });
  }

  void _toggleGenre(String key) {
    final updated = List<String>.from(widget.selectedGenres);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    widget.onChanged(updated);
    widget.onErrorClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + AI button
        Row(children: [
          const Text('Thể loại *',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151))),
          const Spacer(),
          InkWell(
            onTap: _isPredicting ? null : _predictGenre,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isPredicting)
                    const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF2563EB)),
                    )
                  else
                    const Icon(Icons.auto_awesome_rounded,
                        size: 13, color: Color(0xFF2563EB)),
                  const SizedBox(width: 5),
                  Text(
                    _isPredicting ? 'Đang dự đoán...' : 'Gợi ý AI',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Các thể loại đã chọn ─────────────────────────
        if (widget.selectedGenres.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.selectedGenres.map((key) {
                final label = BookGenres.all[key] ?? key;
                return GestureDetector(
                  onTap: () => _toggleGenre(key),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                        const SizedBox(width: 4),
                        const Icon(Icons.close_rounded,
                            size: 11, color: Colors.white70),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Genre chips grid ──────────────────────────────
        // Khi có AI: sắp xếp theo confidence giảm dần + badge %
        // Khi không có AI: alpha order
        // Chỉ hiện thể loại chưa được chọn
        Builder(builder: (_) {
          // Build confidence map từ predictions
          final confMap = <String, double>{
            for (final p in _predictions) p.key: p.confidence,
          };
          final hasAI = _predictions.isNotEmpty;

          // Lấy danh sách chưa chọn
          final unselected = BookGenres.all.entries
              .where((e) => !widget.selectedGenres.contains(e.key))
              .toList();

          // Sắp xếp: nếu có AI → confidence giảm dần, bằng nhau → alpha
          if (hasAI) {
            unselected.sort((a, b) {
              final ca = confMap[a.key] ?? -1;
              final cb = confMap[b.key] ?? -1;
              if (cb != ca) return cb.compareTo(ca);
              return a.value.compareTo(b.value);
            });
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unselected.map((entry) {
              final conf = confMap[entry.key];
              // Nếu AI đã chạy: genre không có trong predictions → 0%
              final pct  = hasAI
                  ? (conf != null ? (conf * 100).round() : 0)
                  : (conf != null ? (conf * 100).round() : null);
              return GestureDetector(
                onTap: () => _toggleGenre(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  decoration: BoxDecoration(
                    // Genre có AI confidence cao → nền tím nhạt
                    color: pct != null && pct > 0
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: pct != null && pct > 0
                          ? const Color(0xFFDDD6FE)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: pct != null && pct > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: pct != null && pct > 0
                                ? const Color(0xFF6D28D9)
                                : const Color(0xFF6B7280),
                          )),
                      if (pct != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: pct > 0
                                ? const Color(0xFF7C3AED).withOpacity(0.12)
                                : const Color(0xFF9CA3AF).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pct%',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: pct > 0
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),

        // Genre error
        if (widget.submitError != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.error_outline_rounded,
                size: 14, color: Color(0xFFEF4444)),
            const SizedBox(width: 6),
            Text(widget.submitError!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFEF4444))),
          ]),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AddBookModal — dùng AppModal + AppModalField
// ─────────────────────────────────────────────────────────────

class AddBookModal extends StatefulWidget {
  const AddBookModal({super.key, required this.service});
  final BookService service;

  @override
  State<AddBookModal> createState() => _AddBookModalState();
}

class _AddBookModalState extends State<AddBookModal>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _yearCtrl   = TextEditingController(
      text: DateTime.now().year.toString());
  final _isbnCtrl   = TextEditingController();
  final _shelfCtrl  = TextEditingController();
  final _stockCtrl  = TextEditingController(text: '1');
  final _descCtrl   = TextEditingController();

  List<String> _selectedGenres = [];
  bool    _isSubmitting = false;
  String? _genreError;

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _titleCtrl, _authorCtrl, _yearCtrl,
      _isbnCtrl, _shelfCtrl, _stockCtrl, _descCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedGenres.isEmpty) {
      setState(() =>
          _genreError = 'Vui lòng chọn ít nhất một thể loại.');
      return;
    }

    setState(() { _isSubmitting = true; _genreError = null; });

    final cmd = CreateBookCommand(
      title:           _titleCtrl.text.trim(),
      author:          _authorCtrl.text.trim(),
      publicationYear: int.parse(_yearCtrl.text.trim()),
      genres:          List.from(_selectedGenres),
      initialStock:    int.parse(_stockCtrl.text.trim()),
      isbn: _isbnCtrl.text.trim().isEmpty
          ? null : _isbnCtrl.text.trim(),
      shelfLocation: _shelfCtrl.text.trim().isEmpty
          ? null : _shelfCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null : _descCtrl.text.trim(),
    );

    final result = await widget.service.createBook(cmd);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        await _animCtrl.reverse();
        if (mounted) Navigator.pop(context, data);
      case Failure(:final message):
        setState(() {
          _isSubmitting = false;
          _genreError   = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      controller: _animCtrl,
      header: AppModalHeader(
        icon:      Icons.menu_book_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBg:    const Color(0xFFEFF6FF),
        title:     'Thêm sách mới',
        subtitle:  'Điền thông tin để thêm đầu sách vào thư viện',
        onClose:   _close,
      ),
      footer: AppModalFooter(
        onCancel:     _close,
        onConfirm:    _submit,
        confirmLabel: 'Thêm sách',
        confirmIcon:  Icons.add_rounded,
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
                  label: 'Tiêu đề *',
                  controller: _titleCtrl,
                  hint: 'Nhập tên sách...',
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Tiêu đề không được để trống' : null,
                )),
                const SizedBox(width: 16),
                Expanded(child: AppModalField(
                  label: 'Tác giả *',
                  controller: _authorCtrl,
                  hint: 'Nhập tên tác giả...',
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Tác giả không được để trống' : null,
                )),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                SizedBox(width: 120, child: AppModalField(
                  label: 'Năm xuất bản *',
                  controller: _yearCtrl,
                  hint: 'VD: 2023',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Không hợp lệ';
                    if (n < 1000 || n > DateTime.now().year)
                      return 'Năm không hợp lệ';
                    return null;
                  },
                )),
                const SizedBox(width: 16),
                Expanded(child: AppModalField(
                  label: 'ISBN',
                  controller: _isbnCtrl,
                  hint: 'VD: 978-3-16-148410-0',
                )),
                const SizedBox(width: 16),
                SizedBox(width: 130, child: AppModalField(
                  label: 'Vị trí kệ sách',
                  controller: _shelfCtrl,
                  hint: 'VD: A1-02',
                )),
                const SizedBox(width: 16),
                SizedBox(width: 100, child: AppModalField(
                  label: 'Số lượng *',
                  controller: _stockCtrl,
                  hint: '1',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Tối thiểu 1';
                    return null;
                  },
                )),
              ]),
              const SizedBox(height: 16),
              AppModalField(
                label: 'Mô tả',
                controller: _descCtrl,
                hint: 'Nhập mô tả ngắn về nội dung sách...',
                maxLines: 3,
              ),
              const AppModalDivider(),
              _GenreSelectorSection(
                service:        widget.service,
                selectedGenres: _selectedGenres,
                titleCtrl:      _titleCtrl,
                descCtrl:       _descCtrl,
                submitError:    _genreError,
                onErrorClear:   () =>
                    setState(() => _genreError = null),
                onChanged: (genres) =>
                    setState(() => _selectedGenres = genres),
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
//  EditBookModal — dùng AppModal + AppModalField
// ─────────────────────────────────────────────────────────────

class EditBookModal extends StatefulWidget {
  const EditBookModal({
    super.key,
    required this.service,
    required this.detail,
  });
  final BookService service;
  final BookDetail  detail;

  @override
  State<EditBookModal> createState() => _EditBookModalState();
}

class _EditBookModalState extends State<EditBookModal>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _shelfCtrl;
  late final TextEditingController _descCtrl;

  List<String> _selectedGenres = [];
  bool    _isSubmitting = false;
  String? _genreError;

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl  = TextEditingController(text: widget.detail.title);
    _authorCtrl = TextEditingController(text: widget.detail.author);
    _yearCtrl   = TextEditingController(
        text: widget.detail.publicationYear.toString());
    _isbnCtrl   = TextEditingController(text: widget.detail.isbn ?? '');
    _shelfCtrl  = TextEditingController(
        text: widget.detail.shelfLocation ?? '');
    _descCtrl   = TextEditingController(
        text: widget.detail.description ?? '');
    _selectedGenres = List.from(widget.detail.genres);

    _animCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _titleCtrl, _authorCtrl, _yearCtrl,
      _isbnCtrl, _shelfCtrl, _descCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedGenres.isEmpty) {
      setState(() =>
          _genreError = 'Vui lòng chọn ít nhất một thể loại.');
      return;
    }

    setState(() { _isSubmitting = true; _genreError = null; });

    final cmd = UpdateBookCommand(
      title:           _titleCtrl.text.trim(),
      author:          _authorCtrl.text.trim(),
      publicationYear: int.parse(_yearCtrl.text.trim()),
      genres:          List.from(_selectedGenres),
      isbn: _isbnCtrl.text.trim().isEmpty
          ? null : _isbnCtrl.text.trim(),
      shelfLocation: _shelfCtrl.text.trim().isEmpty
          ? null : _shelfCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null : _descCtrl.text.trim(),
    );

    final result =
        await widget.service.updateBook(widget.detail.id, cmd);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        await _animCtrl.reverse();
        if (mounted) Navigator.pop(context, data);
      case Failure(:final message):
        setState(() {
          _isSubmitting = false;
          _genreError   = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      controller:      _animCtrl,
      width:           640,
      maxHeightFactor: 0.90,
      header: AppModalHeader(
        icon:      Icons.edit_rounded,
        iconColor: const Color(0xFFF59E0B),
        iconBg:    const Color(0xFFFFF7ED),
        title:     'Chỉnh sửa sách',
        subtitle:  widget.detail.title,
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
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Section 1: Thông tin cơ bản ───────────────
              _EditSection(
                icon:  Icons.book_outlined,
                title: 'Thông tin cơ bản',
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: AppModalField(
                        label:      'Tiêu đề *',
                        controller: _titleCtrl,
                        hint:       'Nhập tên sách...',
                        validator:  (v) => (v?.trim().isEmpty ?? true)
                            ? 'Tiêu đề không được để trống' : null,
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: AppModalField(
                        label:      'Tác giả *',
                        controller: _authorCtrl,
                        hint:       'Nhập tên tác giả...',
                        validator:  (v) => (v?.trim().isEmpty ?? true)
                            ? 'Tác giả không được để trống' : null,
                      )),
                    ]),
                    const SizedBox(height: 14),
                    AppModalField(
                      label:      'Mô tả',
                      controller: _descCtrl,
                      hint:       'Nhập mô tả ngắn về nội dung sách...',
                      maxLines:   5,
                    ),
                  ],
                ),
              ),

              const AppModalDivider(vertical: 18),

              // ── Section 2: Chi tiết xuất bản ──────────────
              _EditSection(
                icon:  Icons.info_outline_rounded,
                title: 'Chi tiết xuất bản',
                child: Row(children: [
                  SizedBox(width: 130, child: AppModalField(
                    label:        'Năm xuất bản *',
                    controller:   _yearCtrl,
                    hint:         'VD: 2023',
                    keyboardType: TextInputType.number,
                    validator:    (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Không hợp lệ';
                      if (n < 1000 || n > DateTime.now().year)
                        return 'Năm không hợp lệ';
                      return null;
                    },
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: AppModalField(
                    label:      'ISBN',
                    controller: _isbnCtrl,
                    hint:       'VD: 978-3-16-148410-0',
                  )),
                  const SizedBox(width: 14),
                  SizedBox(width: 148, child: AppModalField(
                    label:      'Vị trí kệ sách',
                    controller: _shelfCtrl,
                    hint:       'VD: A1-02',
                  )),
                ]),
              ),

              const AppModalDivider(vertical: 18),

              // ── Section 3: Thể loại ───────────────────────
              _EditSection(
                icon:  Icons.label_outline_rounded,
                title: 'Thể loại',
                child: _GenreSelectorSection(
                  service:        widget.service,
                  selectedGenres: _selectedGenres,
                  titleCtrl:      _titleCtrl,
                  descCtrl:       _descCtrl,
                  submitError:    _genreError,
                  onErrorClear:   () =>
                      setState(() => _genreError = null),
                  onChanged: (genres) =>
                      setState(() => _selectedGenres = genres),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _EditSection — section wrapper với icon + title ───────────

class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String   title;
  final Widget   child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14,
                color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _DeleteConfirmDialog
// ─────────────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.book});
  final BookSummary book;

  @override
  State<_DeleteConfirmDialog> createState() =>
      _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState
    extends State<_DeleteConfirmDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _fade;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    await _ctrl.reverse();
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _confirm() async {
    setState(() => _isDeleting = true);
    await _ctrl.reverse();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.center,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 60),
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 32,
                    offset: Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(28, 28, 28, 20),
                  child: Column(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius:
                              BorderRadius.circular(14)),
                      child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 26,
                          color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Xác nhận xoá sách',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6B7280),
                            height: 1.5),
                        children: [
                          const TextSpan(
                              text: 'Bạn có chắc muốn xoá '),
                          TextSpan(
                              text: '"${widget.book.title}"',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827))),
                          const TextSpan(text: ' không?'),
                        ],
                      ),
                    ),
                    if (widget.book.totalStock > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(children: [
                          const Icon(
                              Icons.warning_amber_rounded,
                              size: 15,
                              color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sách hiện có '
                              '${widget.book.totalStock} bản '
                              '(${widget.book.availableStock} khả dụng, '
                              '${widget.book.lentOutCount} đang mượn). '
                              'Toàn bộ dữ liệu sẽ bị xoá vĩnh viễn.',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF92400E),
                                  height: 1.4),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ]),
                ),
                const Divider(
                    height: 1, color: Color(0xFFF3F4F6)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(child: _DialogButton(
                      label:  'Huỷ',
                      filled: false,
                      onTap:  _isDeleting ? null : _cancel,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _DialogButton(
                      label: _isDeleting
                          ? 'Đang xoá...'
                          : 'Xoá sách',
                      filled: true,
                      danger: true,
                      onTap:  _isDeleting ? null : _confirm,
                    )),
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

// ── _DialogButton ─────────────────────────────────────────────

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.label,
    required this.filled,
    this.danger = false,
    this.onTap,
  });
  final String        label;
  final bool          filled;
  final bool          danger;
  final VoidCallback? onTap;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    Color bg, border, text;

    if (widget.filled) {
      bg = disabled
          ? const Color(0xFFFCA5A5)
          : _pressed
              ? const Color(0xFFB91C1C)
              : const Color(0xFFEF4444);
      border = Colors.transparent;
      text   = Colors.white;
    } else {
      bg     = _pressed
          ? const Color(0xFFF3F4F6)
          : Colors.white;
      border = const Color(0xFFE5E7EB);
      text   = disabled
          ? const Color(0xFFD1D5DB)
          : const Color(0xFF374151);
    }

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(widget.label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: text)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BookDetailModal — xem chi tiết sách (read-only)
// ─────────────────────────────────────────────────────────────

class BookDetailModal extends StatefulWidget {
  const BookDetailModal({super.key, required this.detail});
  final BookDetail detail;

  @override
  State<BookDetailModal> createState() => _BookDetailModalState();
}

class _BookDetailModalState extends State<BookDetailModal>
    with SingleTickerProviderStateMixin {
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

  ({String label, Color color, Color bg, Color border}) _statusStyle(BookDetail d) {
    if (d.availableStock == 0) return (
      label:  'Hết hàng',
      color:  const Color(0xFFDC2626),
      bg:     const Color(0xFFFEF2F2),
      border: const Color(0xFFFECACA),
    );
    if (d.availableStock <= 3) return (
      label:  'Sắp hết',
      color:  const Color(0xFFD97706),
      bg:     const Color(0xFFFFFBEB),
      border: const Color(0xFFFDE68A),
    );
    return (
      label:  'Còn sách',
      color:  const Color(0xFF16A34A),
      bg:     const Color(0xFFF0FDF4),
      border: const Color(0xFFBBF7D0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d      = widget.detail;
    final status = _statusStyle(d);

    return AppModal(
      controller:      _animCtrl,
      width:           620,
      maxHeightFactor: 0.88,
      header: AppModalHeader(
        icon:      Icons.menu_book_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBg:    const Color(0xFFEFF6FF),
        title:     'Chi tiết sách',
        subtitle:  d.title,
        onClose:   _close,
      ),
      footer: AppModalFooter(
        onCancel:         _close,
        onConfirm:        _close,
        cancelLabel:      '',
        confirmLabel:     'Đóng',
        showRequiredHint: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Hero: cover + title + genres ──────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0F7FF), Color(0xFFF8FAFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover placeholder
                  Container(
                    width: 72, height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332563EB),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories_rounded,
                            size: 28, color: Colors.white),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            d.publicationYear.toString(),
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFBFDBFE),
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge (top-right feel)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:   status.bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: status.border),
                            ),
                            child: Text(status.label,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: status.color)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(d.title,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                height: 1.35)),
                        const SizedBox(height: 5),
                        Row(children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 14, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text(d.author,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280))),
                        ]),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: d.genres.map((g) {
                            final lbl = BookGenres.all[g] ?? g;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(lbl,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2563EB))),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const AppModalDivider(vertical: 20),

            // ── Stock stats row ────────────────────────────
            Row(children: [
              _StatMini(
                label: 'Tổng bản',
                value: '${d.totalStock}',
                icon:  Icons.inventory_2_outlined,
                color: const Color(0xFF2563EB),
                bg:    const Color(0xFFEFF6FF),
              ),
              const SizedBox(width: 10),
              _StatMini(
                label: 'Khả dụng',
                value: '${d.availableStock}',
                icon:  Icons.check_circle_outline_rounded,
                color: const Color(0xFF16A34A),
                bg:    const Color(0xFFF0FDF4),
              ),
              const SizedBox(width: 10),
              _StatMini(
                label: 'Đang mượn',
                value: '${d.lentOutCount}',
                icon:  Icons.swap_horiz_rounded,
                color: const Color(0xFFD97706),
                bg:    const Color(0xFFFFFBEB),
              ),
            ]),

            const AppModalDivider(vertical: 20),

            // ── Info grid ─────────────────────────────────
            const _SectionLabel(text: 'Thông tin sách'),
            const SizedBox(height: 12),
            _InfoGrid(rows: [
              _InfoRow(
                  icon:  Icons.calendar_today_outlined,
                  label: 'Năm xuất bản',
                  value: '${d.publicationYear}'),
              if (d.isbn != null && d.isbn!.isNotEmpty)
                _InfoRow(
                    icon:  Icons.qr_code_rounded,
                    label: 'ISBN',
                    value: d.isbn!),
              if (d.shelfLocation != null &&
                  d.shelfLocation!.isNotEmpty)
                _InfoRow(
                    icon:  Icons.shelves,
                    label: 'Vị trí kệ sách',
                    value: d.shelfLocation!),
              if (d.addedDate != null)
                _InfoRow(
                  icon:  Icons.add_circle_outline_rounded,
                  label: 'Ngày thêm vào',
                  value: '${d.addedDate!.day.toString().padLeft(2, '0')}/'
                         '${d.addedDate!.month.toString().padLeft(2, '0')}/'
                         '${d.addedDate!.year}',
                ),
            ]),

            // ── Description ───────────────────────────────
            if (d.description != null && d.description!.isNotEmpty) ...[
              const AppModalDivider(vertical: 20),
              const _SectionLabel(text: 'Mô tả'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Text(d.description!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                        height: 1.7)),
              ),
            ],

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── _StatMini — ô stat nhỏ trong detail modal ─────────────────

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final Color    bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ]),
      ),
    );
  }
}

// ── _SectionLabel ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3, height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151))),
    ]);
  }
}

// ── _InfoGrid + _InfoRow ──────────────────────────────────────

class _InfoRow {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
  });
  final String   label;
  final String   value;
  final IconData? icon;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.rows});
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: rows.map((r) => SizedBox(
        width: (620 - 56 - 12) / 2 - 6,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.icon != null) ...[
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(r.icon, size: 14,
                      color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 0.3)),
                    const SizedBox(height: 3),
                    Text(r.value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827))),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  StockUpdateModal — cập nhật số lượng kho
// ─────────────────────────────────────────────────────────────

class StockUpdateModal extends StatefulWidget {
  const StockUpdateModal({
    super.key,
    required this.service,
    required this.detail,
  });
  final BookService service;
  final BookDetail  detail;

  @override
  State<StockUpdateModal> createState() => _StockUpdateModalState();
}

class _StockUpdateModalState extends State<StockUpdateModal>
    with SingleTickerProviderStateMixin {

  // 'add' | 'remove'
  String _mode = 'add';

  final _amountCtrl = TextEditingController(text: '1');
  final _reasonCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  bool    _isLoading = false;
  String? _error;

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
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _error = null; });

    final amount = int.parse(_amountCtrl.text.trim());

    if (_mode == 'add') {
      final result = await widget.service.addInventory(
          widget.detail.id, amount);
      if (!mounted) return;
      switch (result) {
        case Success():
          await _animCtrl.reverse();
          if (mounted) Navigator.pop(context);
        case Failure(:final message):
          setState(() { _isLoading = false; _error = message; });
      }
    } else {
      final result = await widget.service.removeInventory(
        widget.detail.id,
        amount,
        reason: _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      switch (result) {
        case Success():
          await _animCtrl.reverse();
          if (mounted) Navigator.pop(context);
        case Failure<TotalStockDecreaseView>(:final message):
          setState(() { _isLoading = false; _error = message; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;

    return AppModal(
      controller:      _animCtrl,
      width:           460,
      maxHeightFactor: 0.75,
      header: AppModalHeader(
        icon:      Icons.inventory_2_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg:    const Color(0xFFF5F3FF),
        title:     'Cập nhật kho',
        subtitle:  d.title,
        onClose:   _close,
      ),
      footer: AppModalFooter(
        onCancel:     _close,
        onConfirm:    _submit,
        confirmLabel: _mode == 'add' ? 'Nhập kho' : 'Xuất kho',
        confirmIcon:  _mode == 'add'
            ? Icons.add_circle_outline_rounded
            : Icons.remove_circle_outline_rounded,
        isLoading:    _isLoading,
        loadingLabel: 'Đang cập nhật...',
        showRequiredHint: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Current stock summary ─────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE5E7EB)),
                ),
                child: Row(children: [
                  _StockChip(
                    label: 'Tổng',
                    value: d.totalStock,
                    color: const Color(0xFF2563EB),
                    bg:    const Color(0xFFEFF6FF),
                  ),
                  const SizedBox(width: 8),
                  _StockChip(
                    label: 'Khả dụng',
                    value: d.availableStock,
                    color: const Color(0xFF16A34A),
                    bg:    const Color(0xFFF0FDF4),
                  ),
                  const SizedBox(width: 8),
                  _StockChip(
                    label: 'Đang mượn',
                    value: d.lentOutCount,
                    color: const Color(0xFFF59E0B),
                    bg:    const Color(0xFFFFFBEB),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Mode selector ─────────────────────────────
              const Text('Loại thao tác',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _ModeButton(
                  label:    'Nhập kho',
                  subtitle: 'Thêm bản mới vào tổng kho',
                  icon:     Icons.add_circle_outline_rounded,
                  selected: _mode == 'add',
                  color:    const Color(0xFF2563EB),
                  bg:       const Color(0xFFEFF6FF),
                  border:   const Color(0xFFBFDBFE),
                  onTap: () => setState(() {
                    _mode = 'add';
                    _error = null;
                  }),
                )),
                const SizedBox(width: 10),
                Expanded(child: _ModeButton(
                  label:    'Xuất kho',
                  subtitle: 'Giảm kho (hư / mất / thanh lý)',
                  icon:     Icons.remove_circle_outline_rounded,
                  selected: _mode == 'remove',
                  color:    const Color(0xFFEF4444),
                  bg:       const Color(0xFFFEF2F2),
                  border:   const Color(0xFFFECACA),
                  onTap: () => setState(() {
                    _mode = 'remove';
                    _error = null;
                  }),
                )),
              ]),

              const SizedBox(height: 20),

              // ── Amount ────────────────────────────────────
              AppModalField(
                label: 'Số lượng *',
                controller: _amountCtrl,
                hint: 'Nhập số lượng...',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1)
                    return 'Số lượng phải lớn hơn 0';
                  if (_mode == 'remove' &&
                      n > d.availableStock)
                    return 'Không thể xuất hơn số bản khả dụng (${d.availableStock})';
                  return null;
                },
              ),

              // ── Reason (remove only — bắt buộc) ──────────
              if (_mode == 'remove') ...[
                const SizedBox(height: 16),
                AppModalField(
                  label: 'Lý do *',
                  controller: _reasonCtrl,
                  hint: 'VD: Sách bị hỏng, mất, thanh lý...',
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập lý do xuất kho'
                      : null,
                ),
              ],

              // ── Preview ───────────────────────────────────
              const SizedBox(height: 16),
              _StockPreview(
                mode:     _mode,
                current:  d.totalStock,
                amountCtrl: _amountCtrl,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFECACA)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626))),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _StockChip ────────────────────────────────────────────────

class _StockChip extends StatelessWidget {
  const _StockChip({
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
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 20,
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

// ── _ModeButton ───────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });
  final String     label;
  final String     subtitle;
  final IconData   icon;
  final bool       selected;
  final Color      color;
  final Color      bg;
  final Color      border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? bg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? border : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 20,
              color: selected
                  ? color
                  : const Color(0xFFD1D5DB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? color
                            : const Color(0xFF374151))),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
              child: const Icon(Icons.check,
                  size: 10, color: Colors.white),
            ),
        ]),
      ),
    );
  }
}

// ── _StockPreview — hiển thị trước kết quả ───────────────────

class _StockPreview extends StatefulWidget {
  const _StockPreview({
    required this.mode,
    required this.current,
    required this.amountCtrl,
  });
  final String                mode;
  final int                   current;
  final TextEditingController amountCtrl;

  @override
  State<_StockPreview> createState() => _StockPreviewState();
}

class _StockPreviewState extends State<_StockPreview> {
  @override
  void initState() {
    super.initState();
    widget.amountCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final amount =
        int.tryParse(widget.amountCtrl.text.trim()) ?? 0;
    final newTotal = widget.mode == 'add'
        ? widget.current + amount
        : (widget.current - amount).clamp(0, 999999999);

    final isAdd = widget.mode == 'add';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current
          Flexible(child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child:
              Text('${widget.current}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151)))),
            const Text('Hiện tại',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),

          const SizedBox(width: 10),

          // Operator
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: isAdd
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdd ? Icons.add : Icons.remove,
              size: 13,
              color: isAdd
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFEF4444),
            ),
          ),

          const SizedBox(width: 10),

          // Amount
          Flexible(child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child:
              Text('${amount > 0 ? amount : '?'}',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isAdd
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFEF4444)))),
            const Text('Số lượng',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),

          const SizedBox(width: 10),

          // Equals
          const Text('=',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF))),

          const SizedBox(width: 10),

          // Result
          Flexible(child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child:
              Text('$newTotal',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)))),
            const Text('Kết quả',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
        ],
      ),
    );
  }
}