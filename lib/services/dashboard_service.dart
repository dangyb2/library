import '../models/book.dart';
import '../models/borrow.dart';
import '../models/reader.dart';
import '../models/dashboard_stats.dart';
import '../services/book_service.dart';
import '../services/borrow_service.dart';
import '../services/reader_service.dart';

// ─────────────────────────────────────────────────────────────
//  DashboardService
//
//  Không có repository/endpoint riêng.
//  Gọi song song (Future.wait) các service sẵn có rồi tổng hợp.
// ─────────────────────────────────────────────────────────────

class DashboardService {
  DashboardService({
    BookService?   bookService,
    BorrowService? borrowService,
    ReaderService? readerService,
  })  : _books   = bookService   ?? BookService(),
        _borrows  = borrowService  ?? BorrowService(),
        _readers  = readerService  ?? ReaderService();

  final BookService   _books;
  final BorrowService _borrows;
  final ReaderService _readers;

  // ─────────────────────────────────────────────────────────────
  //  Load all sections in parallel
  // ─────────────────────────────────────────────────────────────

  Future<DashboardStats> load() async {
    // Gọi song song — một service chậm/lỗi không block service khác
    final results = await Future.wait([
      _fetchBooks(),
      _fetchBorrows(),
      _fetchReaders(),
    ]);

    final books   = results[0] as List<BookSummary>?;
    final borrows = results[1] as List<BorrowSummaryView>?;
    final readers = results[2] as List<ReaderView>?;

    final bookErr   = results[0] == null ? 'Lỗi tải dữ liệu sách'    : null;
    final borrowErr = results[1] == null ? 'Lỗi tải dữ liệu mượn/trả' : null;
    final readerErr = results[2] == null ? 'Lỗi tải dữ liệu độc giả'  : null;

    return DashboardStats(
      books:           books   != null ? DashboardSection.ok(_aggregateBooks(books))     : DashboardSection.err(bookErr!),
      readers:         readers != null ? DashboardSection.ok(_aggregateReaders(readers)) : DashboardSection.err(readerErr!),
      borrows:         borrows != null ? DashboardSection.ok(_aggregateBorrows(borrows)) : DashboardSection.err(borrowErr!),
      monthly:         borrows != null ? DashboardSection.ok(_buildMonthly(borrows))     : DashboardSection.err(borrowErr!),
      categories:      books   != null ? DashboardSection.ok(_buildCategories(books))    : DashboardSection.err(bookErr!),
      bookAvailability: books  != null ? DashboardSection.ok(_buildAvailability(books))  : DashboardSection.err(bookErr!),
      recentActivity:  borrows != null ? DashboardSection.ok(_buildRecent(borrows))      : DashboardSection.err(borrowErr!),
      loadedAt:        DateTime.now(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Fetch helpers — trả null thay vì throw
  // ─────────────────────────────────────────────────────────────

  Future<List<BookSummary>?> _fetchBooks() async {
    try {
      final r = await _books.fetchBooks();
      return switch (r) {
        Success(:final data) => data,
        Failure()            => null,
      };
    } catch (_) { return null; }
  }

  Future<List<BorrowSummaryView>?> _fetchBorrows() async {
    try {
      final r = await _borrows.listAllBorrows();
      return r.isSuccess ? r.data : null;
    } catch (_) { return null; }
  }

  Future<List<ReaderView>?> _fetchReaders() async {
    try {
      final r = await _readers.findAll();
      return r.isSuccess ? r.data : null;
    } catch (_) { return null; }
  }

  // ─────────────────────────────────────────────────────────────
  //  Aggregators
  // ─────────────────────────────────────────────────────────────

  BookStats _aggregateBooks(List<BookSummary> books) {
    int total = 0, available = 0;
    for (final b in books) {
      total     += b.totalStock;
      available += b.availableStock;
    }
    return BookStats(
      totalTitles:     books.length,
      totalCopies:     total,
      availableCopies: available,
    );
  }

  ReaderStats _aggregateReaders(List<ReaderView> readers) {
    int active = 0, suspended = 0, expired = 0;
    for (final r in readers) {
      if (r.status == ReaderStatus.SUSPENDED) {
        suspended++;
      } else if (r.isMembershipExpired) {
        expired++;
      } else {
        active++;
      }
    }
    return ReaderStats(
      total: readers.length, active: active,
      suspended: suspended,  expired: expired,
    );
  }

  BorrowStats _aggregateBorrows(List<BorrowSummaryView> borrows) {
    int active = 0, overdue = 0, returned = 0, lost = 0;
    for (final b in borrows) {
      switch (b.status) {
        case BorrowStatus.BORROWED:  active++;   break;
        case BorrowStatus.OVERDUE:   overdue++;  break;
        case BorrowStatus.RETURNED:  returned++; break;
        case BorrowStatus.LOST:      lost++;     break;
        case BorrowStatus.CANCELLED: break;
      }
    }
    return BorrowStats(
      total: borrows.length, active: active,
      overdue: overdue, returned: returned, lost: lost,
    );
  }

  // ── Monthly stats: group by borrowDate, 7 months ─────────────

  List<MonthlyBorrowStat> _buildMonthly(List<BorrowSummaryView> borrows) {
    final now = DateTime.now();
    final stats = <String, ({int borrowed, int returned})>{};

    // Init 7 tháng gần nhất
    for (int i = 6; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final key = 'T${m.month}';
      stats[key] = (borrowed: 0, returned: 0);
    }

    for (final b in borrows) {
      final key = 'T${b.borrowDate.month}';
      if (!stats.containsKey(key)) continue;
      final cur = stats[key]!;
      stats[key] = (borrowed: cur.borrowed + 1, returned: cur.returned);

      if (b.returnDate != null) {
        final rKey = 'T${b.returnDate!.month}';
        if (stats.containsKey(rKey)) {
          final rc = stats[rKey]!;
          stats[rKey] = (borrowed: rc.borrowed, returned: rc.returned + 1);
        }
      }
    }

    return stats.entries.map((e) => MonthlyBorrowStat(
      month:    e.key,
      borrowed: e.value.borrowed,
      returned: e.value.returned,
    )).toList();
  }

  // ── Genre display name map ────────────────────────────────────

  static const Map<String, String> _genreNames = {
    'anthology':            'Anthology',
    'art_music':            'Art & Music',
    'audience_adult':       'Adult',
    'audience_childrens':   "Children\'s",
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

  // ── Category/genre distribution ───────────────────────────────

  List<CategoryStat> _buildCategories(List<BookSummary> books) {
    final counts = <String, int>{};
    for (final b in books) {
      for (final g in b.genres) {
        final displayName = _genreNames[g] ?? g;
        counts[displayName] = (counts[displayName] ?? 0) + 1;
      }
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return [];

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <CategoryStat>[];
    double rest = 100;

    for (int i = 0; i < sorted.length && i < 4; i++) {
      final pct = (sorted[i].value / total * 100).roundToDouble();
      result.add(CategoryStat(name: sorted[i].key, percent: pct));
      rest -= pct;
    }
    if (sorted.length > 4 && rest > 0) {
      result.add(CategoryStat(name: 'Khác', percent: rest.clamp(0, 100)));
    }
    return result;
  }

  // ── Book availability for progress bars ───────────────────────

  List<BookAvailability> _buildAvailability(List<BookSummary> books) =>
      books.take(6).map((b) => BookAvailability(
        id:        b.id,
        title:     b.title,
        available: b.availableStock,
        total:     b.totalStock,
      )).toList();

  // ── Recent activity (last 5 borrow records) ───────────────────

  List<RecentActivity> _buildRecent(List<BorrowSummaryView> borrows) {
    final sorted = [...borrows]
      ..sort((a, b) => b.borrowDate.compareTo(a.borrowDate));

    return sorted.take(5).map((b) {
      final status = switch (b.status) {
        BorrowStatus.RETURNED  => 'returned',
        BorrowStatus.OVERDUE   => 'overdue',
        BorrowStatus.LOST      => 'lost',
        BorrowStatus.CANCELLED => 'cancelled',
        _                      => 'borrowing',
      };
      return RecentActivity(
        borrowId:   b.borrowId,
        readerName: b.readerName,
        bookTitle:  b.bookTitle,
        status:     status,
      );
    }).toList();
  }
}