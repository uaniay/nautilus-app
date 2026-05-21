import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'connection_service.dart';
import 'session_label_service.dart';

class NotificationService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  ConnectionService? _connection;
  SessionLabelService? _labelService;
  bool _appInBackground = false;
  bool _initialized = false;

  final void Function(String sessionId)? onNotificationTap;

  NotificationService({this.onNotificationTap});

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void updateDependencies(ConnectionService connection, SessionLabelService labelService) {
    if (_connection == connection && _labelService == labelService) return;
    _eventSub?.cancel();
    _connection = connection;
    _labelService = labelService;
    _eventSub = connection.eventStream.listen(_handleEvent);
  }

  void setAppInBackground(bool inBackground) {
    _appInBackground = inBackground;
  }

  void _handleEvent(Map<String, dynamic> event) {
    if (!_appInBackground) return;

    final type = event['type'] as String?;
    if (type != 'session.output') return;

    final sessionId = event['session_id'] as String?;
    final data = event['data'] as String?;
    if (sessionId == null || data == null || data.isEmpty) return;

    _showNotification(sessionId, data);
  }

  Future<void> _showNotification(String sessionId, String rawOutput) async {
    final label = _labelService?.getLabel(sessionId);
    final title = label ?? 'Session ${sessionId.substring(0, 8)}';
    final body = _stripAnsi(rawOutput).trim();
    if (body.isEmpty) return;

    final truncated = body.length > 100 ? body.substring(0, 100) : body;

    const androidDetails = AndroidNotificationDetails(
      'session_output',
      'Session Output',
      channelDescription: 'Notifications for terminal session output',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      sessionId.hashCode,
      title,
      truncated,
      details,
      payload: sessionId,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    final sessionId = response.payload;
    if (sessionId != null && onNotificationTap != null) {
      onNotificationTap!(sessionId);
    }
  }

  String _stripAnsi(String text) {
    return text.replaceAll(RegExp(r'\x1b\[[0-9;]*[a-zA-Z]'), '');
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}
