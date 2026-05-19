import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/file_entry.dart';
import 'connection_service.dart';

class FileService extends ChangeNotifier {
  ConnectionService? _connection;
  StreamSubscription<Map<String, dynamic>>? _fsSub;

  String _currentPath = '~';
  List<FileEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  String get currentPath => _currentPath;
  List<FileEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateConnection(ConnectionService connection) {
    if (_connection == connection) return;
    _fsSub?.cancel();
    _connection = connection;
    _fsSub = connection.fsStream.listen(_handleFsMessage);
  }

  void _handleFsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'fs.list') {
      final list = msg['entries'] as List<dynamic>? ?? [];
      _entries = list.map((e) => FileEntry.fromJson(e as Map<String, dynamic>)).toList();
      _entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });
      _currentPath = msg['path'] as String? ?? _currentPath;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } else if (type == 'fs.list.error') {
      _isLoading = false;
      _error = msg['message'] as String? ?? 'Failed to list directory';
      notifyListeners();
    }
  }

  void navigateTo(String path) {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _connection?.listDirectory(path);
  }

  void navigateInto(String dirName) {
    final newPath = _currentPath == '/'
        ? '/$dirName'
        : '$_currentPath/$dirName';
    navigateTo(newPath);
  }

  void navigateUp() {
    if (_currentPath == '/' || _currentPath == '~') return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    final parent = parts.isEmpty ? '/' : parts.join('/');
    navigateTo(parent);
  }

  void refresh() {
    navigateTo(_currentPath);
  }

  @override
  void dispose() {
    _fsSub?.cancel();
    super.dispose();
  }
}
