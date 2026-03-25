// ─────────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────────

enum AuditEventType {
    READER_CREATED,
    READER_UPDATED,
    READER_SUSPENDED,
    READER_UNSUSPENDED,
    READER_MEMBERSHIP_EXTENDED,

    // Book events
    BOOK_CREATED,
    BOOK_UPDATED,
    BOOK_DELETED,
    BOOK_STOCK_ADDED,
    BOOK_STOCK_REMOVED,
    BOOK_CHECKED_OUT,
    BOOK_RETURNED_TO_STOCK,
    BOOK_RESTORED,

    // Borrow events
    BOOK_BORROWED,
    BOOK_RETURNED,
    BORROW_EXTENDED,
    BORROW_OVERDUE,
    BOOK_REPORTED_LOST,
    BORROW_UPDATED,
    BORROW_CANCELLED,
    BORROW_UNDO_CANCELLED,

    // Payment
    PAYMENT;
}

extension AuditEventTypeName on AuditEventType {
  String get value => name;

  static AuditEventType fromString(String s) {
    final normalized = s.toUpperCase();
    return AuditEventType.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => throw ArgumentError('Unknown event type: $s'),
    );
  }

  /// Nhãn hiển thị tiếng Việt
  String get viName => switch (this) {
        AuditEventType.READER_CREATED        => 'Tạo độc giả',
        AuditEventType.READER_UPDATED        => 'Cập nhật độc giả',
        AuditEventType.READER_SUSPENDED      => 'Khoá độc giả',
        AuditEventType.READER_UNSUSPENDED    => 'Mở khoá độc giả',
        AuditEventType.READER_MEMBERSHIP_EXTENDED => 'Gia hạn thẻ',
        AuditEventType.BOOK_CREATED          => 'Tạo mượn sách',
        AuditEventType.BOOK_UPDATED          => 'Cập nhật sách',
        AuditEventType.BOOK_DELETED          => 'Xoá sách',
        AuditEventType.BOOK_STOCK_ADDED      => 'Thêm sách vào kho',
        AuditEventType.BOOK_STOCK_REMOVED    => 'Xuất sách khỏi kho',
        AuditEventType.BOOK_CHECKED_OUT      => 'Mượn sách',
        AuditEventType.BOOK_RETURNED_TO_STOCK => 'Trả sách',
        AuditEventType.BOOK_RESTORED         => 'Khôi phục sách',
        AuditEventType.BOOK_BORROWED         => 'Mượn sách',
        AuditEventType.BOOK_RETURNED         => 'Trả sách',
        AuditEventType.BORROW_EXTENDED       => 'Gia hạn mượn',
        AuditEventType.BORROW_OVERDUE        => 'Quá hạn trả',
        AuditEventType.BOOK_REPORTED_LOST     => 'Báo mất sách',
        AuditEventType.BORROW_UPDATED        => 'Cập nhật',
        AuditEventType.BORROW_CANCELLED      => 'Huỷ phiếu',
        AuditEventType.BORROW_UNDO_CANCELLED => 'Hoàn tác huỷ phiếu',
        AuditEventType.PAYMENT               => 'Thanh toán',
      };
}

// ─────────────────────────────────────────────
//  MODELS — Audit Log
// ─────────────────────────────────────────────

class AuditLogSummaryView {
  final String   id;
  final String   rawEventType;
  final String   aggregateId;
  final String   message;
  final DateTime occurredAt;

  const AuditLogSummaryView({
    required this.id,
    required this.rawEventType,
    required this.aggregateId,
    required this.message,
    required this.occurredAt,
  });

  /// Tên hiển thị tiếng Việt
  String get displayEventType {
    try {
      return AuditEventTypeName.fromString(rawEventType).viName;
    } catch (_) {
      return rawEventType;
    }
  }

  factory AuditLogSummaryView.fromJson(Map<String, dynamic> json) =>
      AuditLogSummaryView(
        id:          json['id']          as String,
        rawEventType: json['eventType']  as String,
        aggregateId: json['aggregateId'] as String,
        message:     json['message']     as String,
        occurredAt:  DateTime.parse(json['occurredAt'] as String),
      );

  @override
  String toString() =>
      'AuditLogSummaryView(id: $id, eventType: $rawEventType, occurredAt: $occurredAt)';
}