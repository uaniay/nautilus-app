import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionInfo {
  final String id;
  final String command;
  final String createdAt;
  final String cwd;
  final String lastOutput;

  SessionInfo({
    required this.id,
    required this.command,
    required this.createdAt,
    this.cwd = '',
    this.lastOutput = '',
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] ?? '',
      command: json['command'] ?? '',
      createdAt: json['created_at'] ?? '',
      cwd: json['cwd'] ?? '',
      lastOutput: json['last_output'] ?? '',
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
  final StreamController<Map<String, dynamic>> _fsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _voiceController = StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;
  String get token => _token;
  String? get currentSessionId => _currentSessionId;
  List<SessionInfo> get sessions => _sessions;
  Stream<String> get outputStream => _outputController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<Map<String, dynamic>> get fsStream => _fsController.stream;
  Stream<Map<String, dynamic>> get voiceStream => _voiceController.stream;

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

  Future<bool> login(String url, String username, String password) async {
    try {
      final loginUrl = Uri.parse('$url/api/login');
      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode != 200) {
        debugPrint('Login failed: ${response.statusCode} ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null) return false;

      return connect(url, token);
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
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
          _eventController.add(msg);
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

        case 'fs.list':
          _fsController.add(msg);
          break;

        case 'fs.list.error':
          _fsController.add(msg);
          break;

        case 'voice.transcript':
        case 'voice.status':
        case 'voice.error':
          _voiceController.add(msg);
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

  void createSession(String command, {int cols = 80, int rows = 24, String? cwd}) {
    _send({
      'type': 'session.create',
      'command': command,
      'args': <String>[],
      'env': <String, String>{},
      'cols': cols,
      'rows': rows,
      if (cwd != null) 'cwd': cwd,
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

  void sendInputToSession(String sessionId, String data) {
    _send({
      'type': 'session.input',
      'session_id': sessionId,
      'data': data,
    });
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

  void listDirectory(String path) {
    _send({'type': 'fs.list', 'path': path});
  }

  void sendVoiceStart(String sessionId, {String format = 'pcm16', int sampleRate = 16000, int channels = 1}) {
    _send({
      'type': 'voice.start',
      'session_id': sessionId,
      'format': format,
      'sample_rate': sampleRate,
      'channels': channels,
    });
  }

  void sendVoiceData(String sessionId, String base64Data, int seq) {
    _send({
      'type': 'voice.data',
      'session_id': sessionId,
      'data': base64Data,
      'seq': seq,
    });
  }

  void sendVoiceStop(String sessionId) {
    _send({
      'type': 'voice.stop',
      'session_id': sessionId,
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _outputController.close();
    _eventController.close();
    _fsController.close();
    _voiceController.close();
    super.dispose();
  }
}
