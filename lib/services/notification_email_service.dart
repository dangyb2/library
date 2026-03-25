import '../models/notification_email.dart';
import '../repositories/notification_email_repository.dart';
import '../gateway/api_gateway.dart';

// ─────────────────────────────────────────────
//  NotificationService
// ─────────────────────────────────────────────

class NotificationService {
  NotificationService({NotificationRepository? repository})
      : _repo = repository ?? NotificationRepository();

  final NotificationRepository _repo;

  // ── Internal guard ─────────────────────────

  Future<ServiceResult<T>> _run<T>(Future<T> Function() action) async {
    try {
      return ServiceResult.success(await action());
    } on GatewayException catch (e) {
      return ServiceResult.failure(_mapError(e));
    } catch (e) {
      return ServiceResult.failure('Lỗi không xác định: $e');
    }
  }

  String _mapError(GatewayException e) {
    if (e.isNetworkError) {
      return 'Không thể kết nối đến máy chủ. Kiểm tra lại mạng.';
    }
    return switch (e.statusCode) {
      400        => 'Dữ liệu không hợp lệ: ${e.message}',
      401        => 'Phiên đăng nhập hết hạn.',
      403        => 'Không có quyền thực hiện thao tác này.',
      404        => 'Không tìm thấy thông báo.',
      500        => 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.',
      502 || 503 || 504 => 'Dịch vụ tạm thời không khả dụng.',
      _          => e.message.isNotEmpty ? e.message : 'Đã xảy ra lỗi (${e.statusCode}).',
    };
  }

  // ── Queries ────────────────────────────────

  Future<ServiceResult<List<NotificationSummaryView>>> getAllNotifications() =>
      _run(() => _repo.getAllNotifications());

  Future<ServiceResult<NotificationDetailView>> getNotificationById(
          String id) =>
      _run(() => _repo.getNotificationById(id));

  Future<ServiceResult<List<NotificationSummaryView>>> getNotificationsByType(
          NotificationType type) =>
      _run(() => _repo.getNotificationsByType(type));

  Future<ServiceResult<List<NotificationSummaryView>>> getNotificationsByStatus(
          NotificationStatus status) =>
      _run(() => _repo.getNotificationsByStatus(status));

  /// Lấy danh sách thông báo theo email độc giả
  Future<ServiceResult<List<NotificationSummaryView>>> getNotificationsByEmail(
          String email) =>
      _run(() => _repo.getNotificationsByEmail(email));

  /// Lấy danh sách thông báo trong khoảng thời gian [from] → [to]
  Future<ServiceResult<List<NotificationSummaryView>>> getNotificationsByDateRange(
    DateTime from,
    DateTime to,
  ) =>
      _run(() => _repo.getNotificationsByDateRange(from, to));

  // ── Commands ───────────────────────────────

  /// Gửi lại thông báo thất bại — chỉ áp dụng khi status = FAILED
  Future<ServiceResult<void>> retry(String id) =>
      _run(() => _repo.retry(id));
}

// ─────────────────────────────────────────────
//  ServiceResult<T> — wrapper tránh throw/catch
//  (dùng chung với BorrowService nếu đã có,
//   nếu không thì khai báo tại đây)
// ─────────────────────────────────────────────

class ServiceResult<T> {
  final T?      data;
  final bool    isSuccess;
  final bool    isFailure;
  final String? errorMessage;

  const ServiceResult._({
    this.data,
    required this.isSuccess,
    this.errorMessage,
  }) : isFailure = !isSuccess;

  factory ServiceResult.success(T data) =>
      ServiceResult._(data: data, isSuccess: true);

  factory ServiceResult.failure(String message) =>
      ServiceResult._(isSuccess: false, errorMessage: message);
}