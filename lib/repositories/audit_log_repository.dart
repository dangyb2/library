import 'package:intl/intl.dart';

import '../gateway/api_gateway.dart';
import '../models/audit_log.dart';

// ─────────────────────────────────────────────
//  SERVICE RESULT
//  Wrapper kết quả trả về — khớp với pattern
//  đang dùng trong toàn bộ project
// ─────────────────────────────────────────────

class ServiceResult<T> {
  final T?     data;
  final bool   isSuccess;
  final String? errorMessage;

  const ServiceResult._({
    this.data,
    required this.isSuccess,
    this.errorMessage,
  });

  factory ServiceResult.success(T data) =>
      ServiceResult._(data: data, isSuccess: true);

  factory ServiceResult.failure(String message) =>
      ServiceResult._(isSuccess: false, errorMessage: message);
}

// ─────────────────────────────────────────────
//  AUDIT LOG REPOSITORY
//
//  Các phương thức:
//    listAll()                      → List<AuditLogSummaryView>
//    getById(id)                    → AuditLogDetailView
//    listByEventType(eventType)     → List<AuditLogSummaryView>
//    listByDateRange(from, to)      → List<AuditLogSummaryView>
//    listByAggregate(aggregateId)   → List<AuditLogSummaryView>
// ─────────────────────────────────────────────

class AuditLogRepository {
  AuditLogRepository({AuditLogClient? client})
      : _client = client ?? AppGateway.instance.auditLog;

  final AuditLogClient _client;

  // Định dạng ISO-8601 gửi lên server
  static final _isoFmt =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  // ── Lấy toàn bộ log ───────────────────────

  Future<ServiceResult<List<AuditLogSummaryView>>> listAll() async {
    try {
      final res  = await _client.get('/audit-logs');
      final list = (res.asList())
          .cast<Map<String, dynamic>>()
          .map(AuditLogSummaryView.fromJson)
          .toList();
      return ServiceResult.success(list);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure('Không thể tải danh sách audit log: $e');
    }
  }

  // ── Lấy chi tiết 1 log theo id ────────────

  Future<ServiceResult<AuditLogDetailView>> getById(String id) async {
    try {
      final res    = await _client.get('/audit-logs/$id');
      final detail = AuditLogDetailView.fromJson(res.asMap());
      return ServiceResult.success(detail);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure('Không thể tải chi tiết audit log: $e');
    }
  }

  // ── Lấy log theo loại sự kiện ─────────────

  Future<ServiceResult<List<AuditLogSummaryView>>> listByEventType(
      String eventType) async {
    try {
      final res  = await _client.get('/audit-logs/event-type/$eventType');
      final list = (res.asList())
          .cast<Map<String, dynamic>>()
          .map(AuditLogSummaryView.fromJson)
          .toList();
      return ServiceResult.success(list);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure(
          'Không thể tải log theo event type "$eventType": $e');
    }
  }

  // ── Lấy log theo khoảng thời gian ─────────

  /// [from] và [to] là DateTime — tự động format sang ISO-8601
  Future<ServiceResult<List<AuditLogSummaryView>>> listByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final res  = await _client.get('/audit-logs/date-range',
          queryParams: {'from': _isoFmt.format(from), 'to': _isoFmt.format(to)});
      final list = (res.asList())
          .cast<Map<String, dynamic>>()
          .map(AuditLogSummaryView.fromJson)
          .toList();
      return ServiceResult.success(list);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure(
          'Không thể tải log theo khoảng thời gian: $e');
    }
  }

  // ── Lấy log theo aggregate (entity id) ────

  Future<ServiceResult<List<AuditLogSummaryView>>> listByAggregate(
      String aggregateId) async {
    try {
      final res  = await _client.get('/audit-logs/aggregate/$aggregateId');
      final list = (res.asList())
          .cast<Map<String, dynamic>>()
          .map(AuditLogSummaryView.fromJson)
          .toList();
      return ServiceResult.success(list);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure(
          'Không thể tải log theo aggregate "$aggregateId": $e');
    }
  }
}