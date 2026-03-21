import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../gateway/api_gateway.dart';

// ─────────────────────────────────────────────────────────────
//  Result<T> — sealed wrapper, tránh throw/catch lên UI layer
// ─────────────────────────────────────────────────────────────

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, {this.statusCode, this.isNetwork = false});
  final String message;
  final int?   statusCode;
  final bool   isNetwork;
}

// ─────────────────────────────────────────────────────────────
//  BookService
// ─────────────────────────────────────────────────────────────

class BookService {
  BookService({BookRepository? repository})
      : repository = repository ?? BookRepository();

  final BookRepository repository;

  // ── Internal error guard — bắt GatewayException ──────────

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on GatewayException catch (e) {
      return Failure(
        _mapError(e),
        statusCode: e.statusCode,
        isNetwork:  e.isNetworkError,
      );
    } catch (e) {
      return Failure('Lỗi không xác định: $e');
    }
  }

  String _mapError(GatewayException e) {
    if (e.isNetworkError) {
      return 'Không thể kết nối đến máy chủ sách. Kiểm tra lại mạng.';
    }
    return switch (e.statusCode) {
      400        => 'Dữ liệu không hợp lệ: ${e.message}',
      401        => 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
      403        => 'Bạn không có quyền thực hiện thao tác này.',
      404        => 'Không tìm thấy sách.',
      409        => 'Xung đột dữ liệu: ${e.message}',
      422        => 'Dữ liệu không hợp lệ: ${e.message}',
      500        => 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.',
      502 || 503 || 504 => 'Dịch vụ tạm thời không khả dụng.',
      _          => e.message.isNotEmpty
                       ? e.message
                       : 'Đã xảy ra lỗi (${e.statusCode}).',
    };
  }

  // ─────────────────────────────────────────────────────────
  //  Queries
  // ─────────────────────────────────────────────────────────

  Future<Result<List<BookSummary>>> fetchBooks({
    int?    page,
    int?    size,
    String? genre,
    String? author,
    String? search,
    int?    year,
  }) =>
      _run(() => repository.getBooks(
            page:   page,
            size:   size,
            genre:  genre,
            author: author,
            search: search,
            year:   year,
          ));

  Future<Result<BookDetail>> fetchBookById(String id) =>
      _run(() => repository.getBookById(id));

  Future<Result<List<BookSummary>>> fetchBooksByGenre(String genre) =>
      fetchBooks(genre: genre);

  Future<Result<List<BookSummary>>> searchBooks(String keyword) =>
      fetchBooks(search: keyword.trim());

  Future<Result<List<BookSummary>>> fetchAvailableBooks({
    String? genre,
    String? author,
    String? search,
  }) async {
    final result = await fetchBooks(
        genre: genre, author: author, search: search);
    return switch (result) {
      Success(:final data) =>
        Success(data.where((b) => b.isAvailable).toList()),
      Failure() => result,
    };
  }

  // ─────────────────────────────────────────────────────────
  //  Commands — CRUD
  // ─────────────────────────────────────────────────────────

  Future<Result<BookDetail>> createBook(CreateBookCommand cmd) {
    final err = _validateCreate(cmd);
    if (err != null) return Future.value(Failure(err));
    return _run(() => repository.createBook(cmd));
  }

  Future<Result<BookDetail>> updateBook(String id, UpdateBookCommand cmd) {
    if (id.trim().isEmpty) {
      return Future.value(const Failure('ID sách không được để trống.'));
    }
    return _run(() => repository.updateBook(id, cmd));
  }

  Future<Result<void>> deleteBook(String id) {
    if (id.trim().isEmpty) {
      return Future.value(const Failure('ID sách không được để trống.'));
    }
    return _run(() => repository.deleteBook(id));
  }

  // ─────────────────────────────────────────────────────────
  //  Commands — Stock management
  // ─────────────────────────────────────────────────────────

  Future<Result<BookDetail>> addInventory(String id, int amount) {
    final err = _validateQuantity(amount);
    if (err != null) return Future.value(Failure(err));
    return _run(() => repository.addInventory(id, amount));
  }

  Future<Result<TotalStockDecreaseView>> removeInventory(
      String id, int amount, {String? reason}) {
    final err = _validateQuantity(amount);
    if (err != null) return Future.value(Failure(err));
    return _run(
        () => repository.removeInventory(id, amount, reason: reason));
  }

  Future<Result<BookDetail>> checkoutBook(String id) async {
    final detailResult = await fetchBookById(id);
    return switch (detailResult) {
      Failure() => detailResult,
      Success(:final data) when !data.isAvailable =>
        const Failure('Sách hiện không còn trong kho để cho mượn.'),
      Success() => _run(() => repository.checkoutBook(id)),
    };
  }

  Future<Result<BookDetail>> returnBook(String id) =>
      _run(() => repository.returnBook(id));

  // ─────────────────────────────────────────────────────────
  //  AI — Genre prediction
  // ─────────────────────────────────────────────────────────

  Future<Result<GenrePredictionResponse>> predictGenre({
    String? title,
    String? description,
  }) {
    if ((title == null || title.trim().isEmpty) &&
        (description == null || description.trim().isEmpty)) {
      return Future.value(const Failure(
          'Cần cung cấp tiêu đề hoặc mô tả để dự đoán thể loại.'));
    }
    return _run(() => repository.predictGenre(
          GenrePredictionRequest(title: title, description: description),
        ));
  }

  Future<Result<BookDetail>> createBookWithPredictedGenre(
      CreateBookCommand cmd) async {
    final predResult = await predictGenre(
      title:       cmd.title,
      description: cmd.description,
    );

    final genres = switch (predResult) {
      Success(:final data) => data.predictedGenres.isNotEmpty
          ? data.predictedGenres
          : cmd.genres,
      Failure() => cmd.genres,
    };

    return createBook(CreateBookCommand(
      title:           cmd.title,
      author:          cmd.author,
      publicationYear: cmd.publicationYear,
      genres:          genres,
      initialStock:    cmd.initialStock,
      description:     cmd.description,
      isbn:            cmd.isbn,
      shelfLocation:   cmd.shelfLocation,
    ));
  }

  // ─────────────────────────────────────────────────────────
  //  Validators
  // ─────────────────────────────────────────────────────────

  String? _validateCreate(CreateBookCommand cmd) {
    if (cmd.title.trim().isEmpty) return 'Tiêu đề không được để trống.';
    if (cmd.author.trim().isEmpty) return 'Tác giả không được để trống.';
    if (cmd.publicationYear < 1000 ||
        cmd.publicationYear > DateTime.now().year) {
      return 'Năm xuất bản không hợp lệ.';
    }
    if (cmd.genres.isEmpty) return 'Cần chọn ít nhất một thể loại.';
    if (cmd.initialStock < 0) return 'Số lượng ban đầu không được âm.';
    return null;
  }

  String? _validateQuantity(int quantity) {
    if (quantity <= 0) return 'Số lượng phải lớn hơn 0.';
    return null;
  }
}