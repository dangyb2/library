import '../gateway/api_gateway.dart';
import '../models/reader.dart';

abstract class IReaderRepository {
  // ── Queries ──────────────────────────────────
  Future<List<ReaderView>>      findAll();
  Future<ReaderView>            findById(String id);
  Future<ReaderView>            findByEmail(String email);
  Future<ReaderView>            findByPhone(String phone);
  Future<List<ReaderView>>      findByName(String name);
  Future<List<ReaderView>>      findByStatus(ReaderStatus status);
  Future<String>                getReaderEmail(String id);
  Future<Map<String, String>>   getBatchNames(List<String> ids);
  Future<ReaderEligibilityView> getEligibilityDetails(String readerId);

  // ── Commands ─────────────────────────────────
  Future<Map<String, String>>   create(CreateReaderRequest request);
  Future<ReaderView>            update(String id, UpdateReaderRequest request);
  Future<void>                  delete(String id);
  Future<void>                  suspend(String id, SuspendRequest request);
  Future<void>                  unsuspend(String id);
  Future<void>                  extendMembership(String id, ExtendMemberShipRequest request);
}

class ReaderRepository implements IReaderRepository {
  ReaderRepository({ReaderClient? client})
      : _client = client ?? AppGateway.instance.reader;

  final ReaderClient _client;

  // ── Queries ──────────────────────────────────

  @override
  Future<List<ReaderView>> findAll() async {
    final res = await _client.get('/readers');
    return res.asList().map((e) => ReaderView.fromJson(e)).toList();
  }

  @override
  Future<ReaderView> findById(String id) async {
    final res = await _client.get('/readers/$id');
    return ReaderView.fromJson(res.asMap());
  }

  @override
  Future<ReaderView> findByEmail(String email) async {
    final res = await _client.get(
      '/readers/by-email',
      queryParams: {'email': email},
    );
    return ReaderView.fromJson(res.asMap());
  }

  @override
  Future<ReaderView> findByPhone(String phone) async {
    final res = await _client.get(
      '/readers/by-phone',
      queryParams: {'phone': phone},
    );
    return ReaderView.fromJson(res.asMap());
  }

  @override
  Future<List<ReaderView>> findByName(String name) async {
    final res = await _client.get(
      '/readers/by-name',
      queryParams: {'name': name},
    );
    return res.asList().map((e) => ReaderView.fromJson(e)).toList();
  }

  @override
  Future<List<ReaderView>> findByStatus(ReaderStatus status) async {
    final res = await _client.get(
      '/readers/by-status',
      queryParams: {'status': status.value},
    );
    return res.asList().map((e) => ReaderView.fromJson(e)).toList();
  }

  @override
  Future<String> getReaderEmail(String id) async {
    final res = await _client.get('/readers/$id/email');
    return res.asMap()['email'] as String;
  }

  @override
  Future<Map<String, String>> getBatchNames(List<String> ids) async {
    final res = await _client.get(
      '/readers/batch-names',
      queryParams: {'ids': ids.join(',')},
    );
    return Map<String, String>.from(res.asMap());
  }

  @override
  Future<ReaderEligibilityView> getEligibilityDetails(String readerId) async {
    final res = await _client.get('/readers/$readerId/eligibility-details');
    return ReaderEligibilityView.fromJson(res.asMap());
  }

  // ── Commands ─────────────────────────────────

  @override
  Future<Map<String, String>> create(CreateReaderRequest request) async {
    final res = await _client.post('/readers', body: request.toJson());
    return Map<String, String>.from(res.asMap());
  }

  @override
  Future<ReaderView> update(String id, UpdateReaderRequest request) async {
    final res = await _client.put('/readers/$id', body: request.toJson());
    return ReaderView.fromJson(res.asMap());
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete('/readers/$id');
  }

  @override
  Future<void> suspend(String id, SuspendRequest request) async {
    await _client.post('/readers/$id/suspend', body: request.toJson());
  }

  @override
  Future<void> unsuspend(String id) async {
    await _client.post('/readers/$id/unsuspend', body: <String, String>{});
  }

  @override
  Future<void> extendMembership(
      String id, ExtendMemberShipRequest request) async {
    await _client.post(
      '/readers/$id/extend-membership',
      body: request.toJson(),
    );
  }
}