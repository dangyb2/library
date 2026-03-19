import 'package:intl/intl.dart';

import '../gateway/api_gateway.dart';
import '../models/audit_log.dart';

// ─────────────────────────────────────────────
//  SERVICE RESULT  (dùng chung toàn project)
// ─────────────────────────────────────────────

class ServiceResult<T> {
  final T?      data;
  final bool    isSuccess;
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
//  AUDIT LOG FILTER  —  tham số lọc/sắp xếp
// ─────────────────────────────────────────────

enum AuditLogSortField { occurredAt, eventType, aggregateId }
enum AuditSortOrder    { asc, desc }

class AuditLogFilter {
  /// Lọc theo loại sự kiện (null = tất cả)
  final String? eventType;

  /// Lọc theo aggregate id (null = tất cả)
  final String? aggregateId;

  /// Tìm kiếm tự do trên message
  final String? search;

  /// Khoảng thời gian
  final DateTime? from;
  final DateTime? to;

  /// Sắp xếp
  final AuditLogSortField sortBy;
  final AuditSortOrder    sortOrder;

  const AuditLogFilter({
    this.eventType,
    this.aggregateId,
    this.search,
    this.from,
    this.to,
    this.sortBy    = AuditLogSortField.occurredAt,
    this.sortOrder = AuditSortOrder.desc,
  });

  AuditLogFilter copyWith({
    String?              eventType,
    String?              aggregateId,
    String?              search,
    DateTime?            from,
    DateTime?            to,
    AuditLogSortField?   sortBy,
    AuditSortOrder?      sortOrder,
    bool                 clearEventType    = false,
    bool                 clearAggregateId  = false,
    bool                 clearSearch       = false,
    bool                 clearDateRange    = false,
  }) =>
      AuditLogFilter(
        eventType:   clearEventType   ? null : (eventType   ?? this.eventType),
        aggregateId: clearAggregateId ? null : (aggregateId ?? this.aggregateId),
        search:      clearSearch      ? null : (search      ?? this.search),
        from:        clearDateRange   ? null : (from        ?? this.from),
        to:          clearDateRange   ? null : (to          ?? this.to),
        sortBy:    sortBy    ?? this.sortBy,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  bool get isEmpty =>
      eventType   == null &&
      aggregateId == null &&
      search      == null &&
      from        == null &&
      to          == null;
}

// ─────────────────────────────────────────────
//  AUDIT LOG SERVICE
//
//  Tầng nghiệp vụ giữa UI và Repository:
//   • Gọi đúng endpoint theo filter
//   • Lọc / sắp xếp client-side
//   • Cache danh sách toàn bộ để tránh gọi lại
//   • Format tiện dùng cho UI
// ─────────────────────────────────────────────

class AuditLogService {
  AuditLogService({AuditLogClient? client})
      : _client = client ?? AppGateway.instance.auditLog;

  final AuditLogClient _client;

  // ISO-8601 formatter gửi lên server
  static final _isoFmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  // ── Cache ──────────────────────────────────

  List<AuditLogSummaryView>? _cache;
  DateTime?                  _cacheTime;
  static const _cacheTtl = Duration(minutes: 2);

  bool get _cacheValid =>
      _cache != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  void invalidateCache() {
    _cache     = null;
    _cacheTime = null;
  }

  // ── 1. Lấy danh sách có filter ────────────
  //
  //  Tự chọn endpoint tối ưu:
  //   • filter.aggregateId  → /aggregate/{id}
  //   • filter.eventType    → /event-type/{type}
  //   • filter.from & to    → /date-range
  //   • còn lại             → /audit-logs (có cache)

  Future<ServiceResult<List<AuditLogSummaryView>>> listLogs([
    AuditLogFilter filter = const AuditLogFilter(),
  ]) async {
    try {
      List<AuditLogSummaryView> raw;

      // Chọn endpoint phù hợp nhất
      if (filter.aggregateId != null) {
        raw = await _fetchByAggregate(filter.aggregateId!);
      } else if (filter.from != null && filter.to != null) {
        raw = await _fetchByDateRange(filter.from!, filter.to!);
      } else if (filter.eventType != null) {
        raw = await _fetchByEventType(filter.eventType!);
      } else {
        raw = await _fetchAll();
      }

      // Lọc client-side theo các điều kiện còn lại
      var result = _applyClientFilter(raw, filter);

      // Sắp xếp
      result = _applySort(result, filter.sortBy, filter.sortOrder);

      return ServiceResult.success(result);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure('Không thể tải audit log: $e');
    }
  }

  // ── 2. Lấy chi tiết 1 log ─────────────────

  Future<ServiceResult<AuditLogDetailView>> getDetail(String id) async {
    try {
      final res    = await _client.get('/audit-logs/$id');
      final detail = AuditLogDetailView.fromJson(res.asMap());
      return ServiceResult.success(detail);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure('Không thể tải chi tiết log: $e');
    }
  }

  // ── 3. Lấy danh sách eventType phân biệt ──
  //      (dùng để populate dropdown filter)

  Future<ServiceResult<List<String>>> listEventTypes() async {
    try {
      final all = await _fetchAll();
      final types = all
          .map((l) => l.eventType)
          .toSet()
          .toList()
        ..sort();
      return ServiceResult.success(types);
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure('Không thể tải danh sách event type: $e');
    }
  }

  // ── 4. Thống kê nhanh cho stat cards ──────

  Future<ServiceResult<AuditLogStats>> getStats() async {
    try {
      final all = await _fetchAll();

      // Đếm theo event type
      final countByType = <String, int>{};
      for (final log in all) {
        countByType[log.eventType] =
            (countByType[log.eventType] ?? 0) + 1;
      }

      // Hôm nay
      final today     = DateTime.now();
      final todayLogs = all.where((l) =>
          l.occurredAt.year  == today.year  &&
          l.occurredAt.month == today.month &&
          l.occurredAt.day   == today.day).length;

      // 7 ngày gần nhất
      final weekAgo    = today.subtract(const Duration(days: 7));
      final weekLogs   = all.where((l) =>
          l.occurredAt.isAfter(weekAgo)).length;

      return ServiceResult.success(AuditLogStats(
        total:        all.length,
        todayCount:   todayLogs,
        weekCount:    weekLogs,
        countByType:  countByType,
      ));
    } on GatewayException catch (e) {
      return ServiceResult.failure(e.message);
    } catch (e) {
      return ServiceResult.failure('Không thể tải thống kê log: $e');
    }
  }

  // ── Private: fetch helpers ─────────────────

  Future<List<AuditLogSummaryView>> _fetchAll() async {
    if (_cacheValid) return _cache!;

    final res  = await _client.get('/audit-logs');
    final list = (res.asList())
        .cast<Map<String, dynamic>>()
        .map(AuditLogSummaryView.fromJson)
        .toList();

    _cache     = list;
    _cacheTime = DateTime.now();
    return list;
  }

  Future<List<AuditLogSummaryView>> _fetchByEventType(
      String eventType) async {
    final res = await _client.get('/audit-logs/event-type/$eventType');
    return (res.asList())
        .cast<Map<String, dynamic>>()
        .map(AuditLogSummaryView.fromJson)
        .toList();
  }

  Future<List<AuditLogSummaryView>> _fetchByDateRange(
      DateTime from, DateTime to) async {
    final res = await _client.get('/audit-logs/date-range',
        queryParams: {'from': _isoFmt.format(from), 'to': _isoFmt.format(to)});
    return (res.asList())
        .cast<Map<String, dynamic>>()
        .map(AuditLogSummaryView.fromJson)
        .toList();
  }

  Future<List<AuditLogSummaryView>> _fetchByAggregate(
      String aggregateId) async {
    final res = await _client.get('/audit-logs/aggregate/$aggregateId');
    return (res.asList())
        .cast<Map<String, dynamic>>()
        .map(AuditLogSummaryView.fromJson)
        .toList();
  }

  // ── Private: client-side filter ───────────

  List<AuditLogSummaryView> _applyClientFilter(
    List<AuditLogSummaryView> list,
    AuditLogFilter            filter,
  ) {
    return list.where((log) {
      // eventType (nếu đã fetch bằng /audit-logs hoặc /date-range)
      if (filter.eventType != null &&
          log.eventType != filter.eventType) return false;

      // search tự do trên message
      if (filter.search != null && filter.search!.isNotEmpty) {
        final q = filter.search!.toLowerCase();
        if (!log.message.toLowerCase().contains(q) &&
            !log.eventType.toLowerCase().contains(q) &&
            !log.aggregateId.toLowerCase().contains(q)) {
          return false;
        }
      }

      // Lọc thêm theo ngày nếu fetch từ endpoint khác (không phải date-range)
      if (filter.from != null &&
          log.occurredAt.isBefore(filter.from!)) return false;
      if (filter.to != null &&
          log.occurredAt.isAfter(filter.to!)) return false;

      return true;
    }).toList();
  }

  // ── Private: sort ──────────────────────────

  List<AuditLogSummaryView> _applySort(
    List<AuditLogSummaryView> list,
    AuditLogSortField         field,
    AuditSortOrder            order,
  ) {
    final sorted = List<AuditLogSummaryView>.from(list);
    sorted.sort((a, b) {
      int cmp;
      switch (field) {
        case AuditLogSortField.occurredAt:
          cmp = a.occurredAt.compareTo(b.occurredAt);
        case AuditLogSortField.eventType:
          cmp = a.eventType.compareTo(b.eventType);
        case AuditLogSortField.aggregateId:
          cmp = a.aggregateId.compareTo(b.aggregateId);
      }
      return order == AuditSortOrder.asc ? cmp : -cmp;
    });
    return sorted;
  }
}

// ─────────────────────────────────────────────
//  AUDIT LOG STATS  —  kết quả thống kê nhanh
// ─────────────────────────────────────────────

class AuditLogStats {
  final int                total;
  final int                todayCount;
  final int                weekCount;
  final Map<String, int>   countByType;

  const AuditLogStats({
    required this.total,
    required this.todayCount,
    required this.weekCount,
    required this.countByType,
  });

  /// Event type xuất hiện nhiều nhất
  String? get topEventType {
    if (countByType.isEmpty) return null;
    return countByType.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}