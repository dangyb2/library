// ─────────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────────

enum NotificationType {
  READER_CREATED,
  READER_UPDATED,
  READER_SUSPENDED,
  READER_UNSUSPENDED,
  MEMBERSHIP_EXPIRING,
  MEMBERSHIP_EXPIRED,
  BOOK_BORROWED,
  BOOK_RETURNED,
  BORROWING_EXTENDED,
  BOOK_DUE_SOON,
  BOOK_OVERDUE,
  FINE_GENERATED,
  PAYMENT,
  LOST_BOOK_REPORT,
  CANCEL_SUCCESS,
}

enum NotificationStatus { PENDING, SENT, FAILED }

extension NotificationTypeX on NotificationType {
  String get value => name;

  static NotificationType fromString(String s) =>
      NotificationType.values.firstWhere((e) => e.name == s);

  /// Nhãn hiển thị tiếng Việt
  String get label => switch (this) {
        NotificationType.READER_CREATED      => 'Tạo độc giả',
        NotificationType.READER_UPDATED      => 'Cập nhật độc giả',
        NotificationType.READER_SUSPENDED    => 'Khoá tài khoản',
        NotificationType.READER_UNSUSPENDED  => 'Mở khoá tài khoản',
        NotificationType.MEMBERSHIP_EXPIRING => 'Sắp hết hạn thẻ',
        NotificationType.MEMBERSHIP_EXPIRED  => 'Hết hạn thẻ',
        NotificationType.BOOK_BORROWED       => 'Mượn sách',
        NotificationType.BOOK_RETURNED       => 'Trả sách',
        NotificationType.BORROWING_EXTENDED  => 'Gia hạn mượn',
        NotificationType.BOOK_DUE_SOON       => 'Sắp đến hạn trả',
        NotificationType.BOOK_OVERDUE        => 'Quá hạn trả',
        NotificationType.FINE_GENERATED      => 'Phát sinh tiền phạt',
        NotificationType.PAYMENT             => 'Thanh toán',
        NotificationType.LOST_BOOK_REPORT    => 'Báo mất sách',
        NotificationType.CANCEL_SUCCESS      => 'Huỷ phiếu mượn',
      };
}

extension NotificationStatusX on NotificationStatus {
  String get value => name;

  static NotificationStatus fromString(String s) =>
      NotificationStatus.values.firstWhere((e) => e.name == s);

  String get label => switch (this) {
        NotificationStatus.PENDING => 'Đang chờ',
        NotificationStatus.SENT    => 'Đã gửi',
        NotificationStatus.FAILED  => 'Thất bại',
      };
}

// ─────────────────────────────────────────────
//  NotificationSummaryView
//  GET /notifications
//  GET /notifications/type/{type}
//  GET /notifications/status/{status}
//  GET /notifications/reader/{email}
//  GET /notifications/dates
// ─────────────────────────────────────────────

class NotificationSummaryView {
  final String              id;
  final String              recipientEmail;
  final NotificationType    type;
  final String              subject;
  final NotificationStatus  status;
  final int                 retryCount;
  final DateTime            createdAt;
  final DateTime?           sentAt;

  const NotificationSummaryView({
    required this.id,
    required this.recipientEmail,
    required this.type,
    required this.subject,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.sentAt,
  });

  factory NotificationSummaryView.fromJson(Map<String, dynamic> json) =>
      NotificationSummaryView(
        id:             json['id']             as String,
        recipientEmail: json['recipientEmail'] as String,
        type:           NotificationTypeX.fromString(json['type'] as String),
        subject:        json['subject']        as String? ?? '',
        status:         NotificationStatusX.fromString(json['status'] as String),
        retryCount:     (json['retryCount']    as num? ?? 0).toInt(),
        createdAt:      DateTime.parse(json['createdAt'] as String),
        sentAt:         json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : null,
      );
}

// ─────────────────────────────────────────────
//  NotificationDetailView
//  GET /notifications/{id}
// ─────────────────────────────────────────────

class NotificationDetailView {
  final String              id;
  final String              recipientEmail;
  final NotificationType    type;
  final String              subject;
  final String              content;
  final NotificationStatus  status;
  final int                 retryCount;
  final DateTime            createdAt;
  final DateTime?           sentAt;

  const NotificationDetailView({
    required this.id,
    required this.recipientEmail,
    required this.type,
    required this.subject,
    required this.content,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.sentAt,
  });

  factory NotificationDetailView.fromJson(Map<String, dynamic> json) =>
      NotificationDetailView(
        id:             json['id']             as String,
        recipientEmail: json['recipientEmail'] as String,
        type:           NotificationTypeX.fromString(json['type'] as String),
        subject:        json['subject']        as String? ?? '',
        content:        json['content']        as String? ?? '',
        status:         NotificationStatusX.fromString(json['status'] as String),
        retryCount:     (json['retryCount']    as num? ?? 0).toInt(),
        createdAt:      DateTime.parse(json['createdAt'] as String),
        sentAt:         json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : null,
      );
}