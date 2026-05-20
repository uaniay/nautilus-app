import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connection_service.dart';

class SessionHistoryService extends ChangeNotifier {
  ConnectionService? _connection;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  final Map<String, String> _lastOutput = {};

  void updateConnection(ConnectionService connection) {
    if (_connection == connection) return;
    _eventSub?.cancel();
    _connection = connection;
    _eventSub = connection.eventStream.listen(_handleEvent);
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == 'session.output') {
      final sessionId = event['session_id'] as String?;
      final data = event['data'] as String?;
      if (sessionId != null && data != null && data.isNotEmpty) {
        _lastOutput[sessionId] = data;
        notifyListeners();
      }
    }
  }

  String getLastPreview(String sessionId) {
    final raw = _lastOutput[sessionId];
    if (raw == null || raw.isEmpty) return '';
    final text = _stripAnsi(raw).trim();
    return text.length > 60 ? text.substring(0, 60) : text;
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
