// ─────────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────────

enum BookCondition { NEW, GOOD, WORN, DAMAGED }
enum BorrowStatus { BORROWED, RETURNED, OVERDUE, LOST, CANCELLED }
enum PaymentStatus { NONE, UNPAID, PAID }

extension BookConditionX on BookCondition {
  String get value => name;
  static BookCondition fromString(String s) =>
      BookCondition.values.firstWhere((e) => e.name == s);
}

extension BorrowStatusX on BorrowStatus {
  String get value => name;
  static BorrowStatus fromString(String s) =>
      BorrowStatus.values.firstWhere((e) => e.name == s);
}

extension PaymentStatusX on PaymentStatus {
  String get value => name;
  static PaymentStatus fromString(String s) =>
      PaymentStatus.values.firstWhere((e) => e.name == s);
}

// ─────────────────────────────────────────────
//  REQUEST MODELS
// ─────────────────────────────────────────────

class BorrowRequest {
  final String readerId;
  final String bookId;
  final DateTime dueDate;
  final BookCondition conditionBorrow;

  const BorrowRequest({
    required this.readerId,
    required this.bookId,
    required this.dueDate,
    required this.conditionBorrow,
  });

  Map<String, dynamic> toJson() => {
    'readerId': readerId,
    'bookId': bookId,
    'dueDate': dueDate.toIso8601String().split('T').first,
    'conditionBorrow': conditionBorrow.value,
  };
}

class UpdateBorrowRequest {
  final String? readerId;
  final String? bookId;
  final DateTime? borrowDate;
  final DateTime? dueDate;
  final BookCondition? conditionBorrow;

  const UpdateBorrowRequest({
    this.readerId,
    this.bookId,
    this.borrowDate,
    this.dueDate,
    this.conditionBorrow,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (readerId != null) map['readerId'] = readerId;
    if (bookId != null) map['bookId'] = bookId;
    if (borrowDate != null)
      map['borrowDate'] = borrowDate!.toIso8601String().split('T').first;
    if (dueDate != null)
      map['dueDate'] = dueDate!.toIso8601String().split('T').first;
    if (conditionBorrow != null)
      map['conditionBorrow'] = conditionBorrow!.value;
    return map;
  }
}

class ReturnRequest {
  final BookCondition conditionReturn;

  const ReturnRequest({required this.conditionReturn});

  Map<String, dynamic> toJson() => {'conditionReturn': conditionReturn.value};
}

class ExtendRequest {
  final DateTime newDueDate;

  const ExtendRequest({required this.newDueDate});

  Map<String, dynamic> toJson() => {
    'newDueDate': newDueDate.toIso8601String().split('T').first,
  };
}

// ─────────────────────────────────────────────
//  RESPONSE / VIEW MODELS
// ─────────────────────────────────────────────

class BorrowReceiptView {
  final String borrowId;
  final String readerId;
  final String bookId;
  final DateTime borrowDate;
  final DateTime dueDate;
  final BookCondition conditionBorrow;
  final double price;

  const BorrowReceiptView({
    required this.borrowId,
    required this.readerId,
    required this.bookId,
    required this.borrowDate,
    required this.dueDate,
    required this.conditionBorrow,
    required this.price,
  });

  factory BorrowReceiptView.fromJson(Map<String, dynamic> json) =>
      BorrowReceiptView(
        borrowId: json['borrowId'] as String,
        readerId: json['readerId'] as String,
        bookId: json['bookId'] as String,
        borrowDate: DateTime.parse(json['borrowDate'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        conditionBorrow: BookConditionX.fromString(
          json['conditionBorrow'] as String,
        ),
        price: (json['price'] as num).toDouble(),
      );
}

class BorrowDetailsView {
  final String borrowId;
  final String readerId;
  final String bookId;
  final String bookTitle;   
  final String readerName;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final BookCondition conditionBorrow;
  final BookCondition? conditionReturn;
  final BorrowStatus status;
  final double price;
  final double fine;
  final PaymentStatus paymentStatus;

  const BorrowDetailsView({
    required this.borrowId,
    required this.readerId,
    required this.bookId,
    required this.bookTitle,
    required this.readerName,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.conditionBorrow,
    this.conditionReturn,
    required this.status,
    required this.price,
    required this.fine,
    required this.paymentStatus,
  });

  factory BorrowDetailsView.fromJson(Map<String, dynamic> json) =>
      BorrowDetailsView(
        borrowId: json['borrowId'] as String,
        readerId: json['readerId'] as String,
        bookId: json['bookId'] as String ,
        bookTitle: json['bookTitle'] as String? ?? '',
        readerName: json['readerName'] as String? ?? '',
        borrowDate: DateTime.parse(json['borrowDate'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        returnDate: json['returnDate'] != null
            ? DateTime.parse(json['returnDate'] as String)
            : null,
        conditionBorrow: BookConditionX.fromString(
          json['conditionBorrow'] as String,
        ),
        conditionReturn: json['conditionReturn'] != null
            ? BookConditionX.fromString(json['conditionReturn'] as String)
            : null,
        status: BorrowStatusX.fromString(json['status'] as String),
        price: (json['price'] as num).toDouble(),
        fine: (json['fine'] as num).toDouble(),
        paymentStatus: PaymentStatusX.fromString(
          json['paymentStatus'] as String,
        ),
      );
}

class BorrowSummaryView {
  final String borrowId;
  final String bookId;
  final String bookTitle;
  final String readerName;
  final DateTime borrowDate;
  final DateTime dueDate;
  final BorrowStatus status;

  const BorrowSummaryView({
    required this.borrowId,
    required this.bookId,
    required this.bookTitle,
    required this.readerName,
    required this.borrowDate,
    required this.dueDate,
    required this.status,
  });

  factory BorrowSummaryView.fromJson(Map<String, dynamic> json) =>
      BorrowSummaryView(
        borrowId:   json['borrowId']   as String,
        bookId:     json['bookId']     as String,
        bookTitle:  json['bookTitle']  as String? ?? '',   
        readerName: json['readerName'] as String? ?? '',   
        borrowDate: DateTime.parse(json['borrowDate'] as String),
        dueDate:    DateTime.parse(json['dueDate']    as String),
        status:     BorrowStatusX.fromString(json['status'] as String),
      );
}

class ReturnedBorrowView {
  final String borrowId;
  final String bookId;
  final DateTime returnDate;
  final BookCondition conditionReturn;
  final BorrowStatus status;
  final double fine;
  final double? finalPrice;
  final double? totalAmount;

  const ReturnedBorrowView({
    required this.borrowId,
    required this.bookId,
    required this.returnDate,
    required this.conditionReturn,
    required this.status,
    required this.fine,
    this.finalPrice,
    this.totalAmount,
  });

  factory ReturnedBorrowView.fromJson(Map<String, dynamic> json) =>
      ReturnedBorrowView(
        borrowId: json['borrowId'] as String,
        bookId: json['bookId'] as String,
        returnDate: DateTime.parse(json['returnDate'] as String),
        conditionReturn: BookConditionX.fromString(
          json['conditionReturn'] as String,
        ),
        status: BorrowStatusX.fromString(json['status'] as String),
        fine: (json['fine'] as num).toDouble(),
        finalPrice: json['finalPrice'] != null
            ? (json['finalPrice'] as num).toDouble()
            : null,
        totalAmount: json['totalAmount'] != null
            ? (json['totalAmount'] as num).toDouble()
            : null,
      );
}

class ExtendBorrowResultView {
  final String borrowId;
  final DateTime newDueDate;

  const ExtendBorrowResultView({
    required this.borrowId,
    required this.newDueDate,
  });

  factory ExtendBorrowResultView.fromJson(Map<String, dynamic> json) =>
      ExtendBorrowResultView(
        borrowId:   json['borrowId'] as String,
        newDueDate: DateTime.parse(json['newDueDate'] as String),
      );
}

class OverdueBorrowView {
  final String borrowId;
  final String readerId;
  final String bookId;
  final DateTime dueDate;
  final int daysOverdue;
  final double currentFine;
  final PaymentStatus paymentStatus;

  const OverdueBorrowView({
    required this.borrowId,
    required this.readerId,
    required this.bookId,
    required this.dueDate,
    required this.daysOverdue,
    required this.currentFine,
    required this.paymentStatus,
  });

  factory OverdueBorrowView.fromJson(Map<String, dynamic> json) =>
      OverdueBorrowView(
        borrowId: json['borrowId'] as String,
        readerId: json['readerId'] as String,
        bookId: json['bookId'] as String,
        dueDate: DateTime.parse(json['dueDate'] as String),
        daysOverdue: json['daysOverdue'] as int,
        currentFine: (json['currentFine'] as num).toDouble(),
        paymentStatus: PaymentStatusX.fromString(
          json['paymentStatus'] as String,
        ),
      );
}

// ─────────────────────────────────────────────
//  ReturnPreviewResult — xem trước khi trả sách
//  GET /borrows/{borrowId}/preview
// ─────────────────────────────────────────────

class ReturnPreviewResult {
  final String  borrowId;
  final String  bookTitle;
  final double  currentPrice;
  final double  fine;
  final bool    isOverdue;
  final int     daysBorrowed;
  final double  totalAmount;

  const ReturnPreviewResult({
    required this.borrowId,
    required this.bookTitle,
    required this.currentPrice,
    required this.fine,
    required this.isOverdue,
    required this.daysBorrowed,
    required this.totalAmount,
  });

  factory ReturnPreviewResult.fromJson(Map<String, dynamic> json) =>
      ReturnPreviewResult(
        borrowId:     json['borrowId']     as String,
        bookTitle:    json['bookTitle']    as String? ?? '',
        currentPrice: (json['currentPrice'] as num).toDouble(),
        fine:         (json['fine']         as num).toDouble(),
        isOverdue:    json['isOverdue']    as bool? ?? false,
        daysBorrowed: json['daysBorrowed'] as int? ?? 0,
        totalAmount:  (json['totalAmount']  as num).toDouble(),
      );
}