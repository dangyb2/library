// Models — OpenAPI http://100.71.15.110:8082

// ─── helpers ──────────────────────────────────────────────────
List<String> _strings(dynamic v) =>
    (v as List<dynamic>?)?.cast<String>() ?? [];

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

// ─────────────────────────────────────────────────────────────
//  BookSummary  ←  BookSummaryView
// ─────────────────────────────────────────────────────────────

class BookSummary {
  const BookSummary({
    required this.id,
    required this.title,
    required this.author,
    required this.publicationYear,
    required this.genres,
    required this.totalStock,
    required this.availableStock,
    required this.lentOutCount,
  });

  final String       id;
  final String       title;
  final String       author;
  final int          publicationYear;
  final List<String> genres;
  final int          totalStock;
  final int          availableStock;
  final int          lentOutCount;

  bool get isAvailable => availableStock > 0;
  bool get isLowStock  => availableStock >= 1 && availableStock <= 3;

  factory BookSummary.fromJson(Map<String, dynamic> j) => BookSummary(
        id:              j['id']              as String? ?? '',
        title:           j['title']           as String? ?? '',
        author:          j['author']          as String? ?? '',
        publicationYear: _int(j['publicationYear']),
        genres:          _strings(j['genres']),
        totalStock:      _int(j['totalStock']),
        availableStock:  _int(j['availableStock']),
        lentOutCount:    _int(j['lentOutCount']),
      );

  @override bool   operator ==(Object o) => o is BookSummary && o.id == id;
  @override int    get hashCode          => id.hashCode;
  @override String toString()            => 'BookSummary($id, $title)';
}

// ─────────────────────────────────────────────────────────────
//  BookDetail  ←  BookDetailView
// ─────────────────────────────────────────────────────────────

class BookDetail {
  const BookDetail({
    required this.id,
    required this.title,
    required this.author,
    required this.publicationYear,
    required this.genres,
    required this.totalStock,
    required this.availableStock,
    required this.lentOutCount,
    this.description,
    this.isbn,
    this.shelfLocation,
    this.addedDate,
  });

  final String       id;
  final String       title;
  final String       author;
  final int          publicationYear;
  final List<String> genres;
  final int          totalStock;
  final int          availableStock;
  final int          lentOutCount;
  final String?      description;
  final String?      isbn;
  final String?      shelfLocation;
  final DateTime?    addedDate;       // "date" format — no time component

  bool get isAvailable => availableStock > 0;
  bool get isLowStock  => availableStock >= 1 && availableStock <= 3;

  BookSummary toSummary() => BookSummary(
        id:              id,
        title:           title,
        author:          author,
        publicationYear: publicationYear,
        genres:          genres,
        totalStock:      totalStock,
        availableStock:  availableStock,
        lentOutCount:    lentOutCount,
      );

  factory BookDetail.fromJson(Map<String, dynamic> j) => BookDetail(
        id:              j['id']             as String? ?? '',
        title:           j['title']          as String? ?? '',
        author:          j['author']         as String? ?? '',
        publicationYear: _int(j['publicationYear']),
        genres:          _strings(j['genres']),
        totalStock:      _int(j['totalStock']),
        availableStock:  _int(j['availableStock']),
        lentOutCount:    _int(j['lentOutCount']),
        description:     j['description']    as String?,
        isbn:            j['isbn']           as String?,
        shelfLocation:   j['shelfLocation']  as String?,
        addedDate:       j['addedDate'] != null
                             ? DateTime.tryParse(j['addedDate'] as String)
                             : null,
      );

  @override bool   operator ==(Object o) => o is BookDetail && o.id == id;
  @override int    get hashCode          => id.hashCode;
  @override String toString()            => 'BookDetail($id, $title)';
}

// ─────────────────────────────────────────────────────────────
//  CreateBookCommand  ←  POST /books
//  ⚠ Dùng initialStock (không phải stock)
// ─────────────────────────────────────────────────────────────

class CreateBookCommand {
  const CreateBookCommand({
    required this.title,
    required this.author,
    required this.publicationYear,
    required this.genres,
    required this.initialStock,
    this.description,
    this.isbn,
    this.shelfLocation,
  });

  final String       title;
  final String       author;
  final int          publicationYear;
  final List<String> genres;
  final int          initialStock;
  final String?      description;
  final String?      isbn;
  final String?      shelfLocation;

  Map<String, dynamic> toJson() => {
        'title':           title,
        'author':          author,
        'publicationYear': publicationYear,
        'genres':          genres,
        'initialStock':    initialStock,
        if (description   != null) 'description':  description,
        if (isbn          != null) 'isbn':          isbn,
        if (shelfLocation != null) 'shelfLocation': shelfLocation,
      };
}

// ─────────────────────────────────────────────────────────────
//  UpdateBookCommand  ←  PUT /books/{id}
//  ⚠ Không có stock — dùng PATCH /books/{id}/stock/{add|decrease|return}
// ─────────────────────────────────────────────────────────────

class UpdateBookCommand {
  const UpdateBookCommand({
    this.title,
    this.author,
    this.publicationYear,
    this.genres,
    this.description,
    this.isbn,
    this.shelfLocation,
  });

  final String?       title;
  final String?       author;
  final int?          publicationYear;
  final List<String>? genres;
  final String?       description;
  final String?       isbn;
  final String?       shelfLocation;

  Map<String, dynamic> toJson() => {
        if (title           != null) 'title':           title,
        if (author          != null) 'author':          author,
        if (publicationYear != null) 'publicationYear': publicationYear,
        if (genres          != null) 'genres':          genres,
        if (description     != null) 'description':     description,
        if (isbn            != null) 'isbn':             isbn,
        if (shelfLocation   != null) 'shelfLocation':   shelfLocation,
      };
}

// ─────────────────────────────────────────────────────────────
//  GenrePrediction  ←  POST /books/predict-genre
// ─────────────────────────────────────────────────────────────

class GenrePredictionRequest {
  const GenrePredictionRequest({this.title, this.description});

  final String? title;
  final String? description;

  Map<String, dynamic> toJson() => {
        if (title       != null) 'title':       title,
        if (description != null) 'description': description,
      };
}

class GenrePredictionResponse {
  const GenrePredictionResponse({
    required this.predictedGenres,
    required this.suggestedGenres,
  });

  final List<String> predictedGenres;
  final List<String> suggestedGenres;

  factory GenrePredictionResponse.fromJson(Map<String, dynamic> j) =>
      GenrePredictionResponse(
        predictedGenres: _strings(j['predicted_genres']),
        suggestedGenres: _strings(j['suggested_genres']),
      );
}

// ─────────────────────────────────────────────────────────────
//  ApiErrorResponse
// ─────────────────────────────────────────────────────────────

class ApiErrorResponse {
  const ApiErrorResponse({this.timestamp, this.status, this.error, this.message});

  final DateTime? timestamp;
  final int?      status;
  final String?   error;
  final String?   message;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> j) => ApiErrorResponse(
        timestamp: j['timestamp'] != null
                       ? DateTime.tryParse(j['timestamp'] as String)
                       : null,
        status:  _int(j['status']),
        error:   j['error']   as String?,
        message: j['message'] as String?,
      );

  @override
  String toString() => 'ApiErrorResponse($status: $message)';
}