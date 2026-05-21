import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_service.dart';

class SessionLabelService extends ChangeNotifier {
  final Map<String, String> _labels = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('session_labels');
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _labels.clear();
      map.forEach((k, v) => _labels[k] = v as String);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_labels', jsonEncode(_labels));
  }

  String? getLabel(String sessionId) => _labels[sessionId];

  String getDisplayName(SessionInfo session) {
    final label = _labels[session.id];
    if (label != null && label.isNotEmpty) return label;
    return session.command;
  }

  Future<void> setLabel(String sessionId, String label) async {
    if (label.isEmpty) {
      _labels.remove(sessionId);
    } else {
      _labels[sessionId] = label;
    }
    notifyListeners();
    await _save();
  }

  Future<void> removeLabel(String sessionId) async {
    _labels.remove(sessionId);
    notifyListeners();
    await _save();
  }
}
