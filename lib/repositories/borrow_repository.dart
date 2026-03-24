import '../gateway/api_gateway.dart';
import '../models/borrow.dart';

abstract class IBorrowRepository {
  Future<List<BorrowSummaryView>> listAllBorrows();
  Future<BorrowDetailsView> getBorrowDetails(String borrowId);
  Future<BorrowReceiptView> borrowBook(BorrowRequest request);
  Future<BorrowDetailsView> updateBorrow(String borrowId, UpdateBorrowRequest request);
  Future<ReturnedBorrowView> returnBook(String borrowId, ReturnRequest request);
  Future<LostReportResult> reportLost(String borrowId);
  Future<void> markBookFound(String borrowId);
  Future<ExtendBorrowResultView> extendBorrow(String borrowId, ExtendRequest request);
  Future<void> payFine(String borrowId);
  Future<void> cancelBorrow(String borrowId);
  Future<void> undoCancelBorrow(String borrowId);
  Future<ReturnPreviewResult> getReturnPreview(String borrowId, {String? returnDate});
  Future<List<BorrowSummaryView>> getReaderBorrows(String readerId, {BorrowStatus? status});
  Future<List<OverdueBorrowView>> getOverdueBorrows();
}

class BorrowRepository implements IBorrowRepository {
  BorrowRepository({BorrowClient? client})
      : _client = client ?? AppGateway.instance.borrow;

  final BorrowClient _client;

  @override
  Future<List<BorrowSummaryView>> listAllBorrows() async {
    final res = await _client.get('/borrows');
    return res.asList().map((e) => BorrowSummaryView.fromJson(e)).toList();
  }

  @override
  Future<BorrowDetailsView> getBorrowDetails(String borrowId) async {
    final res = await _client.get('/borrows/$borrowId');
    return BorrowDetailsView.fromJson(res.asMap());
  }

  @override
  Future<BorrowReceiptView> borrowBook(BorrowRequest request) async {
    final res = await _client.post('/borrows', body: request.toJson());
    return BorrowReceiptView.fromJson(res.asMap());
  }

  @override
  Future<BorrowDetailsView> updateBorrow(String borrowId, UpdateBorrowRequest request) async {
    final res = await _client.put('/borrows/$borrowId', body: request.toJson());
    return BorrowDetailsView.fromJson(res.asMap());
  }

  @override
  Future<ReturnedBorrowView> returnBook(String borrowId, ReturnRequest request) async {
    final res = await _client.post('/borrows/$borrowId/return', body: request.toJson());
    return ReturnedBorrowView.fromJson(res.asMap());
  }

  @override
  Future<LostReportResult> reportLost(String borrowId) async {
    final res = await _client.post('/borrows/$borrowId/lost');
    return LostReportResult.fromJson(res.asMap());
  }

  @override
  Future<void> markBookFound(String borrowId) async {
    await _client.post('/borrows/$borrowId/found', body: <String, String>{});
  }

  @override
  Future<ExtendBorrowResultView> extendBorrow(String borrowId, ExtendRequest request) async {
    final res = await _client.post('/borrows/$borrowId/extend', body: request.toJson());
    return ExtendBorrowResultView.fromJson(res.asMap());
  }

  @override
  Future<void> payFine(String borrowId) async {
    await _client.patch('/borrows/$borrowId/payment');
  }

  @override
  Future<void> cancelBorrow(String borrowId) async {
    await _client.patch('/borrows/$borrowId/cancel');
  }

  @override
  Future<void> undoCancelBorrow(String borrowId) async {
    await _client.patch('/borrows/$borrowId/undo-cancel');
  }

  @override
  Future<ReturnPreviewResult> getReturnPreview(String borrowId,
      {String? returnDate}) async {
    final res = await _client.get(
      '/borrows/$borrowId/preview',
      queryParams: returnDate != null ? {'returnDate': returnDate} : null,
    );
    return ReturnPreviewResult.fromJson(res.asMap());
  }

  @override
  Future<List<BorrowSummaryView>> getReaderBorrows(String readerId, {BorrowStatus? status}) async {
    final res = await _client.get(
      '/borrows/reader/$readerId',
      queryParams: status != null ? {'status': status.value} : null,
    );
    return res.asList().map((e) => BorrowSummaryView.fromJson(e)).toList();
  }

  @override
  Future<List<OverdueBorrowView>> getOverdueBorrows() async {
    final res = await _client.get('/borrows/overdue');
    return res.asList().map((e) => OverdueBorrowView.fromJson(e)).toList();
  }
}