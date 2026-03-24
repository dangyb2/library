import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
//  SERVICE ENDPOINTS — khớp với application.yml
// ─────────────────────────────────────────────

class ServiceUrls {
  /// Spring Cloud Gateway — tất cả request đi qua cổng 8080
  static const String gateway = String.fromEnvironment(
    'API_GATEWAY_URL',
    defaultValue: 'http://100.71.15.110:8080',
  );
}

// ─────────────────────────────────────────────
//  GATEWAY EXCEPTION
// ─────────────────────────────────────────────

class GatewayException implements Exception {
  final int? statusCode;
  final String message;
  final String? service;
  final String? path;

  const GatewayException({
    this.statusCode,
    required this.message,
    this.service,
    this.path,
  });

  bool get isNotFound      => statusCode == 404;
  bool get isUnauthorized  => statusCode == 401;
  bool get isForbidden     => statusCode == 403;
  bool get isServerError   => statusCode != null && statusCode! >= 500;
  bool get isNetworkError  => statusCode == null;

  @override
  String toString() =>
      'GatewayException[$service]${statusCode != null ? '(${statusCode})' : '(network)'}: $message';
}

// ─────────────────────────────────────────────
//  GATEWAY RESPONSE
// ─────────────────────────────────────────────

class GatewayResponse {
  final int statusCode;
  final dynamic body;        // parsed JSON
  final String rawBody;
  final Map<String, String> headers;

  const GatewayResponse({
    required this.statusCode,
    required this.body,
    required this.rawBody,
    required this.headers,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Ép body thành Map
  Map<String, dynamic> asMap() => body as Map<String, dynamic>;

  /// Ép body thành List
  List<dynamic> asList() => body as List<dynamic>;
}

// ─────────────────────────────────────────────
//  API GATEWAY
// ─────────────────────────────────────────────

class ApiGateway {
  ApiGateway._({
    required http.Client client,
    this.defaultHeaders = const {},
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableLogging = true,
  }) : _client = TimeoutClient(
          client,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        );

  factory ApiGateway({
    http.Client? client,
    Map<String, String> defaultHeaders = const {},
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
    bool enableLogging = true,
  }) =>
      ApiGateway._(
        client: client ?? http.Client(),
        defaultHeaders: defaultHeaders,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        enableLogging: enableLogging,
      );

  final http.Client _client;
  final Map<String, String> defaultHeaders;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;

  // ── Auth token (set sau khi login) ─────────

  String? _bearerToken;

  void setToken(String token)  => _bearerToken = token;
  void clearToken()            => _bearerToken = null;
  bool get hasToken            => _bearerToken != null;

  // ── Request headers ────────────────────────

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...defaultHeaders,
      if (_bearerToken != null) 'Authorization': 'Bearer $_bearerToken',
      ...?extra,
    };
  }

  // ── HTTP methods ───────────────────────────

  Future<GatewayResponse> get(
    String baseUrl,
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? serviceName,
  }) =>
      _send(
        method: 'GET',
        url: _buildUri(baseUrl, path, queryParams),
        headers: _buildHeaders(headers),
        serviceName: serviceName ?? _serviceNameFrom(baseUrl),
        path: path,
      );

  Future<GatewayResponse> post(
    String baseUrl,
    String path, {
    Object? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? serviceName,
  }) =>
      _send(
        method: 'POST',
        url: _buildUri(baseUrl, path, queryParams),
        headers: _buildHeaders(headers),
        body: body,
        serviceName: serviceName ?? _serviceNameFrom(baseUrl),
        path: path,
      );

  Future<GatewayResponse> put(
    String baseUrl,
    String path, {
    Object? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? serviceName,
  }) =>
      _send(
        method: 'PUT',
        url: _buildUri(baseUrl, path, queryParams),
        headers: _buildHeaders(headers),
        body: body,
        serviceName: serviceName ?? _serviceNameFrom(baseUrl),
        path: path,
      );

  Future<GatewayResponse> patch(
    String baseUrl,
    String path, {
    Object? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? serviceName,
  }) =>
      _send(
        method: 'PATCH',
        url: _buildUri(baseUrl, path, queryParams),
        headers: _buildHeaders(headers),
        body: body,
        serviceName: serviceName ?? _serviceNameFrom(baseUrl),
        path: path,
      );



  Future<GatewayResponse> delete(
    String baseUrl,
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? serviceName,
  }) =>
      _send(
        method: 'DELETE',
        url: _buildUri(baseUrl, path, queryParams),
        headers: _buildHeaders(headers),
        serviceName: serviceName ?? _serviceNameFrom(baseUrl),
        path: path,
      );

  // ── Core send ──────────────────────────────

  Future<GatewayResponse> _send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    Object? body,
    required String serviceName,
    required String path,
  }) async {
    final encodedBody = body != null ? jsonEncode(body) : null;

    if (enableLogging) {
      _log('→ $method $url');
      if (encodedBody != null) _log('  body: $encodedBody');
    }

    http.Response response;

    try {
      response = await _dispatch(
        method: method,
        url: url,
        headers: headers,
        body: encodedBody,
      );
    } on SocketException catch (e) {
      throw GatewayException(
        message: 'Không thể kết nối đến $serviceName: ${e.message}',
        service: serviceName,
        path: path,
      );
    } on TimeoutException catch (_) {
      throw GatewayException(
        message: 'Kết nối đến $serviceName bị timeout',
        service: serviceName,
        path: path,
      );
    } catch (e) {
      throw GatewayException(
        message: 'Lỗi mạng: $e',
        service: serviceName,
        path: path,
      );
    }

    if (enableLogging) {
      _log('← ${response.statusCode} $url');
    }

    final parsed = _parseBody(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GatewayException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(parsed, response.body),
        service: serviceName,
        path: path,
      );
    }

    return GatewayResponse(
      statusCode: response.statusCode,
      body: parsed,
      rawBody: response.body,
      headers: response.headers,
    );
  }

  // ── Dispatch by method ─────────────────────

  Future<http.Response> _dispatch({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    String? body,
  }) {
    return switch (method) {
      'GET'    => _client.get(url, headers: headers),
      'POST'   => _client.post(url, headers: headers, body: body),
      'PUT'    => _client.put(url, headers: headers, body: body),
      'PATCH'  => _client.patch(url, headers: headers, body: body),
      'DELETE' => _client.delete(url, headers: headers),
      _        => throw UnsupportedError('Method $method không được hỗ trợ'),
    };
  }

  // ── Helpers ────────────────────────────────

  Uri _buildUri(
    String baseUrl,
    String path,
    Map<String, String>? queryParams,
  ) {
    final uri = Uri.parse('$baseUrl$path');
    return queryParams != null && queryParams.isNotEmpty
        ? uri.replace(queryParameters: queryParams)
        : uri;
  }

  dynamic _parseBody(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return res.body;
    }
  }

  String _extractErrorMessage(dynamic parsed, String raw) {
    if (parsed is Map<String, dynamic>) {
      return parsed['message'] as String? ??
          parsed['error'] as String? ??
          parsed['detail'] as String? ??
          raw;
    }
    return raw.isNotEmpty ? raw : 'Đã xảy ra lỗi';
  }

  String _serviceNameFrom(String baseUrl) {
    return 'ApiGateway';
  }

  void _log(String msg) =>
      // ignore: avoid_print
      print('[ApiGateway] $msg');
}

// ─────────────────────────────────────────────
//  TIMEOUT CLIENT WRAPPER
// ─────────────────────────────────────────────

class TimeoutClient extends http.BaseClient {
  TimeoutClient(
    this._inner, {
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  final http.Client _inner;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(receiveTimeout);
}

// ─────────────────────────────────────────────
//  SERVICE CLIENTS — mỗi microservice 1 client
// ─────────────────────────────────────────────

/// Client dành riêng cho Borrow Service
/// Gateway route: /api/borrows/** → borrow-service (StripPrefix=1)
class BorrowClient {
  BorrowClient(this._gateway);
  final ApiGateway _gateway;

  static const _base   = ServiceUrls.gateway;
  static const _prefix = '/api';

  Future<GatewayResponse> get(String path,
          {Map<String, String>? queryParams}) =>
      _gateway.get(_base, '$_prefix$path',
          queryParams: queryParams, serviceName: 'BorrowService');

  Future<GatewayResponse> post(String path, {Object? body}) =>
      _gateway.post(_base, '$_prefix$path',
          body: body, serviceName: 'BorrowService');

  Future<GatewayResponse> put(String path, {Object? body}) =>
      _gateway.put(_base, '$_prefix$path',
          body: body, serviceName: 'BorrowService');

  Future<GatewayResponse> patch(String path,
          {Object? body, Map<String, String>? queryParams}) =>
      _gateway.patch(_base, '$_prefix$path',
          body: body, queryParams: queryParams, serviceName: 'BorrowService');

  Future<GatewayResponse> delete(String path) =>
      _gateway.delete(_base, '$_prefix$path',
          serviceName: 'BorrowService');
}

/// Client dành riêng cho Book Service
/// Gateway route: /api/books/** → book-service (StripPrefix=1)
class BookClient {
  BookClient(this._gateway);
  final ApiGateway _gateway;

  static const _base   = ServiceUrls.gateway;
  static const _prefix = '/api';

  Future<GatewayResponse> get(String path,
          {Map<String, String>? queryParams}) =>
      _gateway.get(_base, '$_prefix$path',
          queryParams: queryParams, serviceName: 'BookService');

  Future<GatewayResponse> post(String path, {Object? body}) =>
      _gateway.post(_base, '$_prefix$path',
          body: body, serviceName: 'BookService');

  Future<GatewayResponse> put(String path, {Object? body}) =>
      _gateway.put(_base, '$_prefix$path',
          body: body, serviceName: 'BookService');

  Future<GatewayResponse> patch(String path,
          {Object? body, Map<String, String>? queryParams}) =>
      _gateway.patch(_base, '$_prefix$path',
          body: body, queryParams: queryParams, serviceName: 'BookService');

  Future<GatewayResponse> delete(String path) =>
      _gateway.delete(_base, '$_prefix$path',
          serviceName: 'BookService');
}

/// Client dành riêng cho Reader Service
/// Gateway route: /api/readers/** → reader-service (StripPrefix=1)
class ReaderClient {
  ReaderClient(this._gateway);
  final ApiGateway _gateway;

  static const _base   = ServiceUrls.gateway;
  static const _prefix = '/api';

  Future<GatewayResponse> get(String path,
          {Map<String, String>? queryParams}) =>
      _gateway.get(_base, '$_prefix$path',
          queryParams: queryParams, serviceName: 'ReaderService');

  Future<GatewayResponse> post(String path, {Object? body}) =>
      _gateway.post(_base, '$_prefix$path',
          body: body, serviceName: 'ReaderService');

  Future<GatewayResponse> put(String path, {Object? body}) =>
      _gateway.put(_base, '$_prefix$path',
          body: body, serviceName: 'ReaderService');

  Future<GatewayResponse> patch(String path,
          {Object? body, Map<String, String>? queryParams}) =>
      _gateway.patch(_base, '$_prefix$path',
          body: body, queryParams: queryParams, serviceName: 'ReaderService');

  Future<GatewayResponse> delete(String path) =>
      _gateway.delete(_base, '$_prefix$path',
          serviceName: 'ReaderService');
}

/// Client dành riêng cho Audit Log Service
/// Gateway route: /api/audit-logs/** → audit-log-service (StripPrefix=1)
class AuditLogClient {
  AuditLogClient(this._gateway);
  final ApiGateway _gateway;

  static const _base   = ServiceUrls.gateway;
  static const _prefix = '/api';

  Future<GatewayResponse> get(String path,
          {Map<String, String>? queryParams}) =>
      _gateway.get(_base, '$_prefix$path',
          queryParams: queryParams, serviceName: 'AuditLogService');

  Future<GatewayResponse> post(String path, {Object? body}) =>
      _gateway.post(_base, '$_prefix$path',
          body: body, serviceName: 'AuditLogService');

  Future<GatewayResponse> put(String path, {Object? body}) =>
      _gateway.put(_base, '$_prefix$path',
          body: body, serviceName: 'AuditLogService');

  Future<GatewayResponse> patch(String path,
          {Object? body, Map<String, String>? queryParams}) =>
      _gateway.patch(_base, '$_prefix$path',
          body: body, queryParams: queryParams, serviceName: 'AuditLogService');

  Future<GatewayResponse> delete(String path) =>
      _gateway.delete(_base, '$_prefix$path',
          serviceName: 'AuditLogService');
}

// ─────────────────────────────────────────────
//  SERVICE LOCATOR  (singleton, dùng toàn app)
// ─────────────────────────────────────────────

class AppGateway {
  AppGateway._();
  static final AppGateway _instance = AppGateway._();
  static AppGateway get instance => _instance;

  late final ApiGateway _gateway;
  late final BorrowClient   borrow;
  late final BookClient     book;
  late final ReaderClient   reader;
  late final AuditLogClient auditLog;

  bool _initialized = false;

  /// Gọi một lần duy nhất trong main() hoặc trước khi dùng
  void init({
    bool enableLogging = true,
    Map<String, String> defaultHeaders = const {},
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    if (_initialized) return;

    _gateway = ApiGateway(
      enableLogging: enableLogging,
      defaultHeaders: defaultHeaders,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );

    borrow   = BorrowClient(_gateway);
    book     = BookClient(_gateway);
    reader   = ReaderClient(_gateway);
    auditLog = AuditLogClient(_gateway);

    _initialized = true;
  }

  /// Đặt Bearer token sau khi login
  void setToken(String token) => _gateway.setToken(token);

  /// Xóa token khi logout
  void clearToken() => _gateway.clearToken();
}