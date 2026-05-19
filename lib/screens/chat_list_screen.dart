import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import '../services/session_history_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionService>().listSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionService>();
    final history = context.watch<SessionHistoryService>();
    final sessions = connection.sessions;

    return Column(
      children: [
        _buildHeader(),
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
                      return _buildSessionTile(session, preview);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No active sessions',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Go to Files tab to start a Claude, Codex, or Bash session',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(SessionInfo session, String preview) {
    final icon = _commandIcon(session.command);
    final color = _commandColor(session.command);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(session: session),
          ),
        );
      },
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
                        session.command,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (session.cwd.isNotEmpty) ...[
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
