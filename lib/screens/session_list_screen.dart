import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import '../services/session_history_service.dart';
import '../services/session_label_service.dart';
import 'session_detail_screen.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionService>().listSessions();
    });
  }

  void _showNewSessionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _NewSessionSheet(
        onSelect: (command) {
          Navigator.of(ctx).pop();
          _createSession(command);
        },
      ),
    );
  }

  void _createSession(String command) {
    final connection = context.read<ConnectionService>();

    StreamSubscription<Map<String, dynamic>>? sub;
    sub = connection.eventStream.listen((msg) {
      if (msg['type'] == 'session.created') {
        sub?.cancel();
        final sessionId = msg['session_id'] as String;
        final session = SessionInfo(
          id: sessionId,
          command: command,
          createdAt: DateTime.now().toIso8601String(),
        );
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          );
        }
      }
    });

    connection.createSession(command);
  }

  void _showLabelDialog(SessionInfo session) {
    final labelService = context.read<SessionLabelService>();
    final controller = TextEditingController(
      text: labelService.getLabel(session.id) ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Session Label', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter a label...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              labelService.removeLabel(session.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              labelService.setLabel(session.id, controller.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00D4AA))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();
    final history = context.watch<SessionHistoryService>();
    final labelService = context.watch<SessionLabelService>();
    final sessions = connection.sessions;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          _buildHeader(connection),
          Expanded(
            child: sessions.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF00D4AA),
                    onRefresh: () async {
                      connection.listSessions();
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final preview = history.getLastPreview(session.id);
                        return _buildSessionTile(session, preview, labelService);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewSessionDialog,
        backgroundColor: const Color(0xFF00D4AA),
        child: const Icon(Icons.add, color: Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _buildHeader(ConnectionService connection) {
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
                color: connection.isConnected
                    ? const Color(0xFF00D4AA)
                    : connection.isConnecting
                        ? const Color(0xFFFFE66D)
                        : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.read<ConnectionService>().listSessions(),
              child: const Icon(Icons.refresh, size: 20, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No active sessions',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to start a new session',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(SessionInfo session, String preview, SessionLabelService labelService) {
    final icon = _commandIcon(session.command);
    final color = _commandColor(session.command);
    final displayName = labelService.getDisplayName(session);
    final hasLabel = labelService.getLabel(session.id) != null;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(session: session),
          ),
        );
      },
      onLongPress: () => _showLabelDialog(session),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF222233), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (hasLabel) ...[
                        const SizedBox(width: 8),
                        Text(
                          session.command,
                          style: const TextStyle(fontSize: 12, color: Colors.white38),
                        ),
                      ],
                      if (session.cwd.isNotEmpty && !hasLabel) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.cwd,
                            style: const TextStyle(fontSize: 12, color: Colors.white38),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
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

class _NewSessionSheet extends StatelessWidget {
  final void Function(String command) onSelect;

  const _NewSessionSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'New Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          _buildOption(
            icon: Icons.auto_awesome,
            color: const Color(0xFF00D4AA),
            label: 'Claude',
            description: 'AI coding assistant',
            onTap: () => onSelect('claude'),
          ),
          _buildOption(
            icon: Icons.psychology,
            color: const Color(0xFF4ECDC4),
            label: 'Codex',
            description: 'OpenAI Codex CLI',
            onTap: () => onSelect('codex'),
          ),
          _buildOption(
            icon: Icons.terminal,
            color: const Color(0xFFFFE66D),
            label: 'Bash',
            description: 'Shell terminal',
            onTap: () => onSelect('bash'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color color,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
