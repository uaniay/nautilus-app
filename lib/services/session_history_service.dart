import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'connection_service.dart';

class SessionHistoryService extends ChangeNotifier {
  ConnectionService? _connection;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  final Map<String, List<ChatMessage>> _history = {};

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
        _addMessage(sessionId, MessageDirection.output, data);
      }
    }
  }

  void recordInput(String sessionId, String data) {
    if (data.isEmpty) return;
    _addMessage(sessionId, MessageDirection.input, data);
  }

  void _addMessage(String sessionId, MessageDirection direction, String content) {
    _history.putIfAbsent(sessionId, () => []);
    final messages = _history[sessionId]!;

    // Merge consecutive output messages within 500ms to reduce bubble noise
    if (direction == MessageDirection.output && messages.isNotEmpty) {
      final last = messages.last;
      if (last.direction == MessageDirection.output &&
          DateTime.now().difference(last.timestamp).inMilliseconds < 500) {
        messages[messages.length - 1] = ChatMessage(
          sessionId: sessionId,
          direction: direction,
          content: last.content + content,
          timestamp: last.timestamp,
        );
        notifyListeners();
        return;
      }
    }

    messages.add(ChatMessage(
      sessionId: sessionId,
      direction: direction,
      content: content,
    ));
    notifyListeners();
  }

  List<ChatMessage> getHistory(String sessionId) {
    return _history[sessionId] ?? [];
  }

  String getLastPreview(String sessionId) {
    final messages = _history[sessionId];
    if (messages == null || messages.isEmpty) return '';
    final last = messages.last;
    final text = _stripAnsi(last.content).trim();
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
