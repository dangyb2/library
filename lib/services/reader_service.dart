import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../gateway/api_gateway.dart';

// ─────────────────────────────────────────────
//  ServiceResult<T> — wrapper tránh throw/catch
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

// ─────────────────────────────────────────────
//  ReaderService
// ─────────────────────────────────────────────

class ReaderService {
  ReaderService({ReaderRepository? repository})
      : _repo = repository ?? ReaderRepository();

  final ReaderRepository _repo;

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
      404        => 'Không tìm thấy độc giả.',
      409        => 'Xung đột dữ liệu: ${e.message}',
      422        => 'Dữ liệu không hợp lệ: ${e.message}',
      500        => 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.',
      502 || 503 || 504 => 'Dịch vụ tạm thời không khả dụng.',
      _          => e.message.isNotEmpty
          ? e.message
          : 'Đã xảy ra lỗi (${e.statusCode}).',
    };
  }

  // ── Queries ────────────────────────────────

  Future<ServiceResult<List<ReaderView>>> findAll() =>
      _run(() => _repo.findAll());

  Future<ServiceResult<ReaderView>> findById(String id) =>
      _run(() => _repo.findById(id));

  Future<ServiceResult<ReaderView>> findByEmail(String email) =>
      _run(() => _repo.findByEmail(email));

  Future<ServiceResult<ReaderView>> findByPhone(String phone) =>
      _run(() => _repo.findByPhone(phone));

  Future<ServiceResult<List<ReaderView>>> findByName(String name) =>
      _run(() => _repo.findByName(name));

  Future<ServiceResult<List<ReaderView>>> findByStatus(ReaderStatus status) =>
      _run(() => _repo.findByStatus(status));

  Future<ServiceResult<ReaderEligibilityView>> getEligibilityDetails(
          String readerId) =>
      _run(() => _repo.getEligibilityDetails(readerId));

  Future<ServiceResult<Map<String, String>>> getBatchNames(
          List<String> ids) =>
      _run(() => _repo.getBatchNames(ids));

  // ── Commands ───────────────────────────────

  Future<ServiceResult<Map<String, String>>> create(
      CreateReaderRequest request) {
    final err = _validateCreate(request);
    if (err != null) return Future.value(ServiceResult.failure(err));
    return _run(() => _repo.create(request));
  }

  Future<ServiceResult<ReaderView>> update(
      String id, UpdateReaderRequest request) {
    final err = _validateUpdate(request);
    if (err != null) return Future.value(ServiceResult.failure(err));
    return _run(() => _repo.update(id, request));
  }

  Future<ServiceResult<void>> delete(String id) =>
      _run(() => _repo.delete(id));

  Future<ServiceResult<void>> suspend(
      String id, SuspendRequest request) {
    if (request.reason.trim().isEmpty) {
      return Future.value(
          ServiceResult.failure('Lý do khoá không được để trống.'));
    }
    return _run(() => _repo.suspend(id, request));
  }

  Future<ServiceResult<void>> unsuspend(String id) =>
      _run(() => _repo.unsuspend(id));

  Future<ServiceResult<void>> extendMembership(
      String id, ExtendMemberShipRequest request) {
    if (request.newExpireDate.isBefore(DateTime.now())) {
      return Future.value(ServiceResult.failure(
          'Ngày gia hạn phải sau ngày hôm nay.'));
    }
    return _run(() => _repo.extendMembership(id, request));
  }

  // ── Validators ─────────────────────────────

  String? _validateCreate(CreateReaderRequest r) {
    if (r.name.trim().isEmpty) return 'Tên không được để trống.';
    if (r.email.trim().isEmpty) return 'Email không được để trống.';
    if (!r.email.contains('@')) return 'Email không hợp lệ.';
    if (r.phone.trim().isEmpty) return 'Số điện thoại không được để trống.';
    return null;
  }

  String? _validateUpdate(UpdateReaderRequest r) {
    if (r.name.trim().isEmpty) return 'Tên không được để trống.';
    if (r.email.trim().isEmpty) return 'Email không được để trống.';
    if (!r.email.contains('@')) return 'Email không hợp lệ.';
    if (r.phone.trim().isEmpty) return 'Số điện thoại không được để trống.';
    return null;
  }
}