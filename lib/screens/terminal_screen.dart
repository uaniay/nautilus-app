import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../services/connection_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late Terminal _terminal;
  late TerminalController _terminalController;
  StreamSubscription<String>? _outputSub;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  String _selectedCommand = 'bash';
  bool _showSessionList = false;

  final List<String> _commands = ['bash', 'zsh', 'claude', 'codex'];

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _terminalController = TerminalController();

    final service = context.read<ConnectionService>();

    _terminal.onOutput = (data) {
      service.sendInput(data);
    };

    _terminal.onResize = (cols, rows, _, __) {
      service.resizeSession(cols, rows);
    };

    _outputSub = service.outputStream.listen((data) {
      _terminal.write(data);
    });

    _eventSub = service.eventStream.listen((event) {
      final type = event['type'];
      switch (type) {
        case 'session.created':
          _terminal.write('\x1b[2J\x1b[H');
          break;
        case 'session.attached':
          _terminal.write('\x1b[2J\x1b[H');
          break;
        case 'session.exit':
          _terminal.write('\r\n\x1b[33m[Process exited with code ${event['code']}]\x1b[0m\r\n');
          break;
        case 'error':
          _terminal.write('\r\n\x1b[31m[Error: ${event['message']}]\x1b[0m\r\n');
          break;
        case 'disconnected':
          _terminal.write('\r\n\x1b[31m[Connection lost]\x1b[0m\r\n');
          break;
      }
    });
  }

  @override
  void dispose() {
    _outputSub?.cancel();
    _eventSub?.cancel();
    _terminalController.dispose();
    super.dispose();
  }

  void _createSession() {
    final service = context.read<ConnectionService>();
    service.createSession(_selectedCommand, cols: _terminal.viewWidth, rows: _terminal.viewHeight);
    setState(() => _showSessionList = false);
  }

  void _toggleSessionList() {
    final service = context.read<ConnectionService>();
    service.listSessions();
    setState(() => _showSessionList = !_showSessionList);
  }

  void _attachSession(String sessionId) {
    final service = context.read<ConnectionService>();
    service.attachSession(sessionId);
    setState(() => _showSessionList = false);
  }

  void _disconnectAndGoBack() {
    final service = context.read<ConnectionService>();
    service.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConnectionService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _disconnectAndGoBack,
          tooltip: 'Disconnect',
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: service.isConnected
                    ? const Color(0xFF00D4AA)
                    : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Nautilus', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedCommand,
            dropdownColor: const Color(0xFF16213E),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: _commands.map((cmd) {
              return DropdownMenuItem(value: cmd, child: Text(cmd));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCommand = val);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createSession,
            tooltip: 'New Session',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _toggleSessionList,
            tooltip: 'Sessions',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                TerminalView(
                  _terminal,
                  controller: _terminalController,
                  autofocus: true,
                  textStyle: const TerminalStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  theme: const TerminalTheme(
                    cursor: Color(0xFF00D4AA),
                    selection: Color(0xFF33475B),
                    foreground: Color(0xFFEEEEEE),
                    background: Color(0xFF1A1A2E),
                    black: Color(0xFF000000),
                    red: Color(0xFFFF6B6B),
                    green: Color(0xFF00D4AA),
                    yellow: Color(0xFFFFE66D),
                    blue: Color(0xFF4ECDC4),
                    magenta: Color(0xFFC792EA),
                    cyan: Color(0xFF89DDFF),
                    white: Color(0xFFEEEEEE),
                    brightBlack: Color(0xFF666666),
                    brightRed: Color(0xFFFF8A80),
                    brightGreen: Color(0xFF69F0AE),
                    brightYellow: Color(0xFFFFFF8D),
                    brightBlue: Color(0xFF80D8FF),
                    brightMagenta: Color(0xFFEA80FC),
                    brightCyan: Color(0xFFA7FDEB),
                    brightWhite: Color(0xFFFFFFFF),
                    searchHitBackground: Color(0xFFFFE66D),
                    searchHitBackgroundCurrent: Color(0xFFFF6B6B),
                    searchHitForeground: Color(0xFF000000),
                  ),
                ),
                if (_showSessionList)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildSessionList(service),
                  ),
              ],
            ),
          ),
          _buildShortcutBar(),
        ],
      ),
    );
  }

  Widget _buildSessionList(ConnectionService service) {
    return Container(
      width: 300,
      constraints: const BoxConstraints(maxHeight: 400),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Active Sessions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          if (service.sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No active sessions',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...service.sessions.map((s) {
              final isActive = s.id == service.currentSessionId;
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.terminal,
                  size: 18,
                  color: isActive ? const Color(0xFF00D4AA) : Colors.grey,
                ),
                title: Text(
                  s.command,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF00D4AA) : Colors.white,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  s.id.substring(0, 8),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: isActive
                    ? const Icon(Icons.check, size: 16, color: Color(0xFF00D4AA))
                    : null,
                onTap: () => _attachSession(s.id),
              );
            }),
        ],
      ),
    );
  }

  bool _ctrlActive = false;

  void _sendKey(String key) {
    final service = context.read<ConnectionService>();
    if (_ctrlActive) {
      // Send Ctrl+key (ASCII control character)
      final code = key.toUpperCase().codeUnitAt(0) - 64;
      if (code > 0 && code < 32) {
        service.sendInput(String.fromCharCode(code));
      }
      setState(() => _ctrlActive = false);
    } else {
      service.sendInput(key);
    }
  }

  Widget _buildShortcutBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _shortcutBtn('ESC', () => _sendKey('\x1b')),
            _shortcutBtn('TAB', () => _sendKey('\t')),
            _shortcutBtn(
              'CTRL',
              () => setState(() => _ctrlActive = !_ctrlActive),
              active: _ctrlActive,
            ),
            _shortcutBtn('Ctrl+C', () => _sendKey('\x03')),
            _shortcutBtn('Ctrl+D', () => _sendKey('\x04')),
            _shortcutBtn('Ctrl+Z', () => _sendKey('\x1a')),
            _shortcutBtn('Ctrl+L', () => _sendKey('\x0c')),
            _shortcutBtn('↑', () => _sendKey('\x1b[A')),
            _shortcutBtn('↓', () => _sendKey('\x1b[B')),
            _shortcutBtn('←', () => _sendKey('\x1b[D')),
            _shortcutBtn('→', () => _sendKey('\x1b[C')),
            _shortcutBtn('HOME', () => _sendKey('\x1b[H')),
            _shortcutBtn('END', () => _sendKey('\x1b[F')),
            _shortcutBtn('PGUP', () => _sendKey('\x1b[5~')),
            _shortcutBtn('PGDN', () => _sendKey('\x1b[6~')),
          ],
        ),
      ),
    );
  }

  Widget _shortcutBtn(String label, VoidCallback onTap, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF00D4AA) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? const Color(0xFF00D4AA) : const Color(0xFF444444),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
            ),
          ),
        ),
      ),
    );
  }
}
