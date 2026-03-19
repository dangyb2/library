import '../models/book.dart';
import '../gateway/api_gateway.dart';

// ─────────────────────────────────────────────────────────────
//  BookRepository  —  dùng BookClient từ ApiGateway
//  (bỏ ApiException — GatewayException đã được throw từ gateway)
// ─────────────────────────────────────────────────────────────

class BookRepository {
  BookRepository({BookClient? client})
      : _client = client ?? AppGateway.instance.book;

  final BookClient _client;

  // ── GET /books ────────────────────────────────────────────

  Future<List<BookSummary>> getBooks({
    int?    page,
    int?    size,
    String? genre,
    String? author,
    String? search,
    int?    year,
  }) async {
    final params = <String, String>{
      if (page   != null) 'page':   '$page',
      if (size   != null) 'size':   '$size',
      if (genre  != null) 'genre':  genre,
      if (author != null) 'author': author,
      if (search != null) 'search': search,
      if (year   != null) 'year':   '$year',
    };

    final res = await _client.get(
      '/books',
      queryParams: params.isNotEmpty ? params : null,
    );
    return res.asList()
        .cast<Map<String, dynamic>>()
        .map(BookSummary.fromJson)
        .toList();
  }

  // ── GET /books/{id} ───────────────────────────────────────

  Future<BookDetail> getBookById(String id) async {
    final res = await _client.get('/books/$id');
    return BookDetail.fromJson(res.asMap());
  }

  // ── POST /books ───────────────────────────────────────────

  Future<BookDetail> createBook(CreateBookCommand cmd) async {
    final res = await _client.post('/books', body: cmd.toJson());
    return BookDetail.fromJson(res.asMap());
  }

  // ── PUT /books/{id} ───────────────────────────────────────

  Future<BookDetail> updateBook(String id, UpdateBookCommand cmd) async {
    final res = await _client.put('/books/$id', body: cmd.toJson());
    return BookDetail.fromJson(res.asMap());
  }

  // ── DELETE /books/{id} ───────────────────────────────────

  Future<void> deleteBook(String id) async {
    await _client.delete('/books/$id');
  }

  // ── PATCH /books/{id}/stock/add-inventory ────────────────

  Future<BookDetail> addInventory(String id, int amount) async {
    final res = await _client.patch(
      '/books/$id/stock/add-inventory',
      queryParams: {'amount': '$amount'},
    );
    return BookDetail.fromJson(res.asMap());
  }

  // ── PATCH /books/{id}/stock/remove-inventory ─────────────

  Future<void> removeInventory(String id, int amount,
      {String? reason}) async {
    final body = <String, dynamic>{'amount': amount};
    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason.trim();
    }
    await _client.patch('/books/$id/stock/remove-inventory', body: body);
  }

  // ── PATCH /books/{id}/stock/checkout ─────────────────────

  Future<BookDetail> checkoutBook(String id) async {
    final res = await _client.patch('/books/$id/stock/checkout');
    return BookDetail.fromJson(res.asMap());
  }

  // ── PATCH /books/{id}/stock/return ───────────────────────

  Future<BookDetail> returnBook(String id) async {
    final res = await _client.patch('/books/$id/stock/return');
    return BookDetail.fromJson(res.asMap());
  }

  // ── POST /books/predict-genre ─────────────────────────────

  Future<GenrePredictionResponse> predictGenre(
      GenrePredictionRequest request) async {
    final res = await _client.post(
      '/books/predict-genre',
      body: request.toJson(),
    );
    return GenrePredictionResponse.fromJson(res.asMap());
  }
}