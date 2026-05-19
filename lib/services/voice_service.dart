import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'connection_service.dart';

class VoiceService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<Map<String, dynamic>>? _voiceSub;

  bool _isRecording = false;
  String _interimText = '';
  String? _activeSessionId;
  int _seq = 0;

  bool get isRecording => _isRecording;
  String get interimText => _interimText;
  String? get activeSessionId => _activeSessionId;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording(String sessionId, ConnectionService connection) async {
    if (_isRecording) return;

    final hasPerms = await _recorder.hasPermission();
    if (!hasPerms) return;

    _activeSessionId = sessionId;
    _seq = 0;
    _interimText = '';
    _isRecording = true;
    notifyListeners();

    connection.sendVoiceStart(sessionId);

    _voiceSub = connection.voiceStream.listen((msg) {
      final type = msg['type'];
      if (msg['session_id'] != sessionId) return;

      switch (type) {
        case 'voice.transcript':
          _interimText = msg['text'] ?? '';
          notifyListeners();
          if (msg['is_final'] == true) {
            Future.delayed(const Duration(seconds: 2), () {
              if (_interimText == msg['text']) {
                _interimText = '';
                notifyListeners();
              }
            });
          }
          break;
        case 'voice.error':
          debugPrint('Voice error: ${msg['message']}');
          stopRecording(connection);
          break;
        case 'voice.status':
          if (msg['active'] == false) {
            _isRecording = false;
            notifyListeners();
          }
          break;
      }
    });

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _audioSub = stream.listen((data) {
      if (!_isRecording) return;
      final base64Data = base64Encode(data);
      connection.sendVoiceData(sessionId, base64Data, _seq++);
    });
  }

  Future<void> stopRecording(ConnectionService connection) async {
    if (!_isRecording) return;

    _isRecording = false;
    notifyListeners();

    await _audioSub?.cancel();
    _audioSub = null;

    await _recorder.stop();

    if (_activeSessionId != null) {
      connection.sendVoiceStop(_activeSessionId!);
    }

    _voiceSub?.cancel();
    _voiceSub = null;
    _activeSessionId = null;
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    _voiceSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
