// ─────────────────────────────────────────────────────────────
//  DashboardStats — model tổng hợp từ nhiều service
// ─────────────────────────────────────────────────────────────

class BookStats {
  final int totalTitles;
  final int totalCopies;
  final int availableCopies;

  const BookStats({
    required this.totalTitles,
    required this.totalCopies,
    required this.availableCopies,
  });

  int get checkedOutCopies => totalCopies - availableCopies;

  factory BookStats.empty() =>
      const BookStats(totalTitles: 0, totalCopies: 0, availableCopies: 0);
}

class ReaderStats {
  final int total;
  final int active;
  final int suspended;
  final int expired;

  const ReaderStats({
    required this.total,
    required this.active,
    required this.suspended,
    required this.expired,
  });

  factory ReaderStats.empty() =>
      const ReaderStats(total: 0, active: 0, suspended: 0, expired: 0);
}

class BorrowStats {
  final int total;
  final int active;
  final int overdue;
  final int returned;
  final int lost;

  const BorrowStats({
    required this.total,
    required this.active,
    required this.overdue,
    required this.returned,
    required this.lost,
  });

  factory BorrowStats.empty() =>
      const BorrowStats(total: 0, active: 0, overdue: 0, returned: 0, lost: 0);
}

// ── Chart data ────────────────────────────────────────────────

class MonthlyBorrowStat {
  final String month;    // "T9", "T10", ...
  final int    borrowed;
  final int    returned;

  const MonthlyBorrowStat({
    required this.month,
    required this.borrowed,
    required this.returned,
  });
}

class CategoryStat {
  final String name;
  final double percent;

  const CategoryStat({required this.name, required this.percent});
}

class BookAvailability {
  final String id;
  final String title;
  final int    available;
  final int    total;

  const BookAvailability({
    required this.id,
    required this.title,
    required this.available,
    required this.total,
  });

  double get ratio => total == 0 ? 0 : available / total;
}

class RecentActivity {
  final String borrowId;
  final String readerName;
  final String bookTitle;
  final String status; // 'borrowing' | 'returned' | 'overdue' | 'lost'

  const RecentActivity({
    required this.borrowId,
    required this.readerName,
    required this.bookTitle,
    required this.status,
  });
}

// ── Section wrapper ───────────────────────────────────────────

class DashboardSection<T> {
  final T?      data;
  final String? error;

  const DashboardSection({this.data, this.error});

  bool get hasData  => data != null;
  bool get hasError => error != null;

  factory DashboardSection.ok(T data)      => DashboardSection(data: data);
  factory DashboardSection.err(String msg) => DashboardSection(error: msg);
}

// ── Aggregate model ───────────────────────────────────────────

class DashboardStats {
  final DashboardSection<BookStats>               books;
  final DashboardSection<ReaderStats>             readers;
  final DashboardSection<BorrowStats>             borrows;
  final DashboardSection<List<MonthlyBorrowStat>> monthly;
  final DashboardSection<List<CategoryStat>>      categories;
  final DashboardSection<List<BookAvailability>>  bookAvailability;
  final DashboardSection<List<RecentActivity>>    recentActivity;
  final DateTime                                  loadedAt;

  const DashboardStats({
    required this.books,
    required this.readers,
    required this.borrows,
    required this.monthly,
    required this.categories,
    required this.bookAvailability,
    required this.recentActivity,
    required this.loadedAt,
  });

  bool get allFailed =>
      books.hasError && readers.hasError && borrows.hasError;
}