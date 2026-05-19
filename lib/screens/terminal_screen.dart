import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../services/connection_service.dart';
import '../widgets/shortcut_bar.dart';

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
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _terminal.write('\x1b[2J\x1b[H');
            }
          });
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

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConnectionService>();

    return Column(
      children: [
        _buildTopBar(service),
        Expanded(
          child: TerminalView(
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
        ),
        ShortcutBar(onSend: (data) {
          final service = context.read<ConnectionService>();
          service.sendInput(data);
        }),
      ],
    );
  }

  Widget _buildTopBar(ConnectionService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
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
            Text(
              service.currentSessionId != null
                  ? 'Session: ${service.currentSessionId!.substring(0, 8)}'
                  : 'No session',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const Spacer(),
            if (service.currentSessionId == null)
              GestureDetector(
                onTap: () {
                  service.createSession('bash',
                      cols: _terminal.viewWidth, rows: _terminal.viewHeight);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'New Bash',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
