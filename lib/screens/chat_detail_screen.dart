import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../services/connection_service.dart';
import '../services/voice_service.dart';
import '../widgets/shortcut_bar.dart';

class ChatDetailScreen extends StatefulWidget {
  final SessionInfo session;

  const ChatDetailScreen({super.key, required this.session});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late Terminal _terminal;
  late TerminalController _terminalController;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _terminalController = TerminalController();

    final connection = context.read<ConnectionService>();

    _terminal.onOutput = (data) {
      connection.sendInputToSession(widget.session.id, data);
    };

    _terminal.onResize = (cols, rows, _, __) {
      if (connection.currentSessionId == widget.session.id) {
        connection.resizeSession(cols, rows);
      }
    };

    _eventSub = connection.eventStream.listen((msg) {
      final type = msg['type'];
      if (msg['session_id'] != widget.session.id) return;

      switch (type) {
        case 'session.attached':
          _terminal.write('\x1b[2J\x1b[H');
          break;
        case 'session.output':
          _terminal.write(msg['data'] ?? '');
          break;
        case 'session.exit':
          _terminal.write(
              '\r\n\x1b[33m[Process exited with code ${msg['code']}]\x1b[0m\r\n');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.of(context).pop();
          });
          break;
        case 'error':
          _terminal
              .write('\r\n\x1b[31m[Error: ${msg['message']}]\x1b[0m\r\n');
          break;
      }
    });

    connection.attachSession(widget.session.id);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = context.watch<VoiceService>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          _buildAppBar(),
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
                if (voiceService.interimText.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: const Color(0xCC16213E),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              voiceService.interimText,
                              style: const TextStyle(
                                color: Color(0xFF00D4AA),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ShortcutBar(
            onSend: (data) {
              final connection = context.read<ConnectionService>();
              connection.sendInputToSession(widget.session.id, data);
            },
            isMicActive: voiceService.isRecording,
            onMicPressed: () {
              final connection = context.read<ConnectionService>();
              if (voiceService.isRecording) {
                voiceService.stopRecording(connection);
              } else {
                voiceService.startRecording(widget.session.id, connection);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              color: Colors.white70,
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _commandColor(widget.session.command).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _commandIcon(widget.session.command),
                color: _commandColor(widget.session.command),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.session.command,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.session.id.substring(0, 8),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, size: 22),
              color: Colors.redAccent,
              tooltip: 'Kill session',
              onPressed: () {
                final connection = context.read<ConnectionService>();
                connection.killSession(widget.session.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _commandIcon(String command) {
    switch (command) {
      case 'claude':
        return Icons.auto_awesome;
      case 'codex':
        return Icons.psychology;
      default:
        return Icons.terminal;
    }
  }

  Color _commandColor(String command) {
    switch (command) {
      case 'claude':
        return const Color(0xFF00D4AA);
      case 'codex':
        return const Color(0xFF4ECDC4);
      default:
        return const Color(0xFFFFE66D);
    }
  }
}
