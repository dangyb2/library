import '../models/borrow.dart';
import '../repositories/borrow_repository.dart';
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
//  BorrowService
// ─────────────────────────────────────────────

class BorrowService {
  BorrowService({BorrowRepository? repository})
      : _repo = repository ?? BorrowRepository();

  final BorrowRepository _repo;

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
      404        => 'Không tìm thấy phiếu mượn.',
      409        => 'Xung đột dữ liệu: ${e.message}',
      422        => 'Dữ liệu không hợp lệ: ${e.message}',
      500        => 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.',
      502 || 503 || 504 => 'Dịch vụ tạm thời không khả dụng.',
      _          => e.message.isNotEmpty ? e.message : 'Đã xảy ra lỗi (${e.statusCode}).',
    };
  }

  // ── Queries ────────────────────────────────

  Future<ServiceResult<List<BorrowSummaryView>>> listAllBorrows() =>
      _run(() => _repo.listAllBorrows());

  Future<ServiceResult<BorrowDetailsView>> getBorrowDetails(String borrowId) =>
      _run(() => _repo.getBorrowDetails(borrowId));

  Future<ServiceResult<List<BorrowSummaryView>>> getReaderBorrows(
    String readerId, {
    BorrowStatus? status,
  }) =>
      _run(() => _repo.getReaderBorrows(readerId, status: status));

  Future<ServiceResult<List<OverdueBorrowView>>> getOverdueBorrows() =>
      _run(() => _repo.getOverdueBorrows());

  // ── Commands ───────────────────────────────

  Future<ServiceResult<BorrowReceiptView>> borrowBook(BorrowRequest request) =>
      _run(() => _repo.borrowBook(request));

  Future<ServiceResult<BorrowDetailsView>> updateBorrow(
    String borrowId,
    UpdateBorrowRequest request,
  ) =>
      _run(() => _repo.updateBorrow(borrowId, request));

  Future<ServiceResult<ReturnedBorrowView>> returnBook(
    String borrowId,
    ReturnRequest request,
  ) =>
      _run(() => _repo.returnBook(borrowId, request));

  Future<ServiceResult<LostReportResult>> reportLost(String borrowId) =>
      _run(() => _repo.reportLost(borrowId));

  /// Đánh dấu tìm lại được sách — áp dụng khi status = LOST
  /// POST /borrows/{borrowId}/found
  Future<ServiceResult<void>> markBookFound(String borrowId) =>
      _run(() => _repo.markBookFound(borrowId));

  Future<ServiceResult<ExtendBorrowResultView>> extendBorrow(
    String borrowId,
    ExtendRequest request, {
    DateTime? currentDueDate,
  }) =>
      _run(() => _repo.extendBorrow(borrowId, request));

  Future<ServiceResult<void>> payFine(String borrowId) =>
      _run(() => _repo.payFine(borrowId));

  /// Huỷ phiếu mượn — chỉ áp dụng khi status = BORROWED
  Future<ServiceResult<void>> cancelBorrow(String borrowId) =>
      _run(() => _repo.cancelBorrow(borrowId));

  /// Hoàn tác huỷ phiếu — chỉ áp dụng khi status = CANCELLED
  Future<ServiceResult<void>> undoCancelBorrow(String borrowId) =>
      _run(() => _repo.undoCancelBorrow(borrowId));

  /// Xem trước tiền phạt / tổng tiền khi trả sách
  Future<ServiceResult<ReturnPreviewResult>> getReturnPreview(
    String borrowId, {
    DateTime? returnDate,
  }) =>
      _run(() => _repo.getReturnPreview(
            borrowId,
            returnDate: returnDate != null
                ? returnDate.toIso8601String().split('T').first
                : null,
          ));
}