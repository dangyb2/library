import 'package:my_app/models/notification_email.dart' show NotificationSummaryView;

import '../gateway/api_gateway.dart';
import '../models/notification_email.dart';

abstract class INotificationRepository {
  Future<List<NotificationSummaryView>> getAllNotifications();
  Future<NotificationDetailView> getNotificationById(String id);
  Future<List<NotificationSummaryView>> getNotificationsByType(NotificationType type);
  Future<List<NotificationSummaryView>> getNotificationsByStatus(NotificationStatus status);
  Future<List<NotificationSummaryView>> getNotificationsByEmail(String email);
  Future<List<NotificationSummaryView>> getNotificationsByDateRange(DateTime from, DateTime to);
  Future<void> retry(String id);
}

class NotificationRepository implements INotificationRepository {
  NotificationRepository({NotificationClient? client})
      : _client = client ?? AppGateway.instance.notification;

  final NotificationClient _client;

  @override
  Future<List<NotificationSummaryView>> getAllNotifications() async {
    final res = await _client.get('/notifications');
    return res.asList().map((e) => NotificationSummaryView.fromJson(e)).toList();
  }

  @override
  Future<NotificationDetailView> getNotificationById(String id) async {
    final res = await _client.get('/notifications/$id');
    return NotificationDetailView.fromJson(res.asMap());
  }

  @override
  Future<List<NotificationSummaryView>> getNotificationsByType(
      NotificationType type) async {
    final res = await _client.get('/notifications/type/${type.value}');
    return res.asList().map((e) => NotificationSummaryView.fromJson(e)).toList();
  }

  @override
  Future<List<NotificationSummaryView>> getNotificationsByStatus(
      NotificationStatus status) async {
    final res = await _client.get('/notifications/status/${status.value}');
    return res.asList().map((e) => NotificationSummaryView.fromJson(e)).toList();
  }

  @override
  Future<List<NotificationSummaryView>> getNotificationsByEmail(
      String email) async {
    final res = await _client.get('/notifications/reader/$email');
    return res.asList().map((e) => NotificationSummaryView.fromJson(e)).toList();
  }

  @override
  Future<List<NotificationSummaryView>> getNotificationsByDateRange(
      DateTime from, DateTime to) async {
    final res = await _client.get(
      '/notifications/dates',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to':   to.toUtc().toIso8601String(),
      },
    );
    return res.asList().map((e) => NotificationSummaryView.fromJson(e)).toList();
  }

  @override
  Future<void> retry(String id) async {
    await _client.post('/notifications/$id/retry', body: <String, String>{});
  }
}