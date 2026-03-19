// ─────────────────────────────────────────────
//  MODELS — Audit Log
//  Sinh từ OpenAPI: /audit-logs (port 8085)
// ─────────────────────────────────────────────

/// Tóm tắt 1 audit log (dùng trong danh sách)
class AuditLogSummaryView {
  final String   id;
  final String   eventType;
  final String   aggregateId;
  final String   message;
  final DateTime occurredAt;

  const AuditLogSummaryView({
    required this.id,
    required this.eventType,
    required this.aggregateId,
    required this.message,
    required this.occurredAt,
  });

  factory AuditLogSummaryView.fromJson(Map<String, dynamic> json) =>
      AuditLogSummaryView(
        id:          json['id']          as String,
        eventType:   json['eventType']   as String,
        aggregateId: json['aggregateId'] as String,
        message:     json['message']     as String,
        occurredAt:  DateTime.parse(json['occurredAt'] as String),
      );

  @override
  String toString() =>
      'AuditLogSummaryView(id: $id, eventType: $eventType, occurredAt: $occurredAt)';
}

/// Chi tiết 1 audit log — bao gồm snapshot before/after
class AuditLogDetailView {
  final String   id;
  final String   eventType;
  final String   aggregateId;
  final String?  before;       // JSON snapshot trước khi thay đổi
  final String?  after;        // JSON snapshot sau khi thay đổi
  final String   message;
  final DateTime occurredAt;

  const AuditLogDetailView({
    required this.id,
    required this.eventType,
    required this.aggregateId,
    this.before,
    this.after,
    required this.message,
    required this.occurredAt,
  });

  factory AuditLogDetailView.fromJson(Map<String, dynamic> json) =>
      AuditLogDetailView(
        id:          json['id']          as String,
        eventType:   json['eventType']   as String,
        aggregateId: json['aggregateId'] as String,
        before:      json['before']      as String?,
        after:       json['after']       as String?,
        message:     json['message']     as String,
        occurredAt:  DateTime.parse(json['occurredAt'] as String),
      );

  @override
  String toString() =>
      'AuditLogDetailView(id: $id, eventType: $eventType, occurredAt: $occurredAt)';
}