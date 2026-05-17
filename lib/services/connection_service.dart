import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionInfo {
  final String id;
  final String command;
  final String createdAt;

  SessionInfo({required this.id, required this.command, required this.createdAt});

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] ?? '',
      command: json['command'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ConnectionService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _serverUrl = '';
  String _token = '';
  String? _currentSessionId;
  List<SessionInfo> _sessions = [];

  final StreamController<String> _outputController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;
  String get token => _token;
  String? get currentSessionId => _currentSessionId;
  List<SessionInfo> get sessions => _sessions;
  Stream<String> get outputStream => _outputController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  Future<void> loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('server_url') ?? '';
    _token = prefs.getString('token') ?? '';
    notifyListeners();
  }

  Future<void> saveSettings(String url, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    await prefs.setString('token', token);
    _serverUrl = url;
    _token = token;
  }

  Future<bool> connect(String url, String token) async {
    try {
      await saveSettings(url, token);

      final wsUrl = url.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      final uri = Uri.parse('$wsUrl/ws?token=${Uri.encodeComponent(token)}');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isConnected = true;
      _serverUrl = url;
      _token = token;
      notifyListeners();

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onDone: () => _onDisconnected(),
        onError: (_) => _onDisconnected(),
      );

      return true;
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _currentSessionId = null;
    notifyListeners();
  }

  void _onDisconnected() {
    _isConnected = false;
    _currentSessionId = null;
    notifyListeners();
    _eventController.add({'type': 'disconnected'});
  }

  void reconnect() {
    if (_serverUrl.isNotEmpty && _token.isNotEmpty) {
      connect(_serverUrl, _token).then((success) {
        if (success && _currentSessionId != null) {
          attachSession(_currentSessionId!);
        }
      });
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'session.created':
          _currentSessionId = msg['session_id'];
          notifyListeners();
          _eventController.add(msg);
          break;

        case 'session.attached':
          _currentSessionId = msg['session_id'];
          if (msg['replay'] != null) {
            _outputController.add(msg['replay']);
          }
          notifyListeners();
          _eventController.add(msg);
          break;

        case 'session.output':
          if (msg['session_id'] == _currentSessionId) {
            _outputController.add(msg['data'] ?? '');
          }
          break;

        case 'session.exit':
          if (msg['session_id'] == _currentSessionId) {
            _currentSessionId = null;
            notifyListeners();
          }
          _eventController.add(msg);
          break;

        case 'session.list':
          final list = msg['sessions'] as List<dynamic>? ?? [];
          _sessions = list.map((s) => SessionInfo.fromJson(s)).toList();
          notifyListeners();
          _eventController.add(msg);
          break;

        case 'error':
          _eventController.add(msg);
          break;
      }
    } catch (_) {}
  }

  void _send(Map<String, dynamic> msg) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(msg));
    }
  }

  void createSession(String command, {int cols = 80, int rows = 24}) {
    _send({
      'type': 'session.create',
      'command': command,
      'args': <String>[],
      'env': <String, String>{},
      'cols': cols,
      'rows': rows,
    });
  }

  void sendInput(String data) {
    if (_currentSessionId != null) {
      _send({
        'type': 'session.input',
        'session_id': _currentSessionId,
        'data': data,
      });
    }
  }

  void resizeSession(int cols, int rows) {
    if (_currentSessionId != null) {
      _send({
        'type': 'session.resize',
        'session_id': _currentSessionId,
        'cols': cols,
        'rows': rows,
      });
    }
  }

  void killSession(String sessionId) {
    _send({
      'type': 'session.kill',
      'session_id': sessionId,
    });
  }

  void attachSession(String sessionId) {
    _send({
      'type': 'session.attach',
      'session_id': sessionId,
    });
  }

  void listSessions() {
    _send({'type': 'session.list'});
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _outputController.close();
    _eventController.close();
    super.dispose();
  }
}
