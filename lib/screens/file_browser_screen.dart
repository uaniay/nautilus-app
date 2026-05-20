import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/file_service.dart';
import '../services/connection_service.dart';
import '../models/file_entry.dart';
import 'session_detail_screen.dart';

class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fileService = context.read<FileService>();
      if (fileService.entries.isEmpty && !fileService.isLoading) {
        fileService.navigateTo('~');
      }
    });
  }

  void _launchSession(String command) {
    final fileService = context.read<FileService>();
    final connection = context.read<ConnectionService>();
    final navigator = Navigator.of(context);

    StreamSubscription<Map<String, dynamic>>? sub;
    sub = connection.eventStream.listen((msg) {
      if (msg['type'] == 'session.created') {
        sub?.cancel();
        final sessionId = msg['session_id'] as String;
        final session = SessionInfo(
          id: sessionId,
          command: command,
          createdAt: DateTime.now().toIso8601String(),
          cwd: fileService.currentPath,
        );
        if (mounted) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          );
        }
      }
    });

    connection.createSession(command, cwd: fileService.currentPath);
  }

  @override
  Widget build(BuildContext context) {
    final fileService = context.watch<FileService>();

    return Column(
      children: [
        _buildPathBar(fileService),
        Expanded(child: _buildFileList(fileService)),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildPathBar(FileService fileService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (fileService.currentPath != '~' && fileService.currentPath != '/')
              GestureDetector(
                onTap: fileService.navigateUp,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_back, size: 20, color: Colors.white70),
                ),
              ),
            const Icon(Icons.folder_open, size: 18, color: Color(0xFF00D4AA)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileService.currentPath,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: fileService.refresh,
              child: const Icon(Icons.refresh, size: 20, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(FileService fileService) {
    if (fileService.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
      );
    }

    if (fileService.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                fileService.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: fileService.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (fileService.entries.isEmpty) {
      return const Center(
        child: Text(
          'Empty directory',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      itemCount: fileService.entries.length,
      itemBuilder: (context, index) {
        final entry = fileService.entries[index];
        return _buildFileTile(entry);
      },
    );
  }

  Widget _buildFileTile(FileEntry entry) {
    final icon = entry.isDirectory
        ? const Icon(Icons.folder, color: Color(0xFF00D4AA), size: 22)
        : Icon(_fileIcon(entry.name), color: Colors.white54, size: 22);

    return InkWell(
      onTap: entry.isDirectory
          ? () => context.read<FileService>().navigateInto(entry.name)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF222233), width: 0.5)),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.name,
                style: TextStyle(
                  fontSize: 14,
                  color: entry.isDirectory ? Colors.white : Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.isDirectory)
              const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'go':
      case 'rs':
      case 'java':
      case 'kt':
      case 'swift':
        return Icons.code;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'toml':
      case 'xml':
        return Icons.settings;
      case 'md':
      case 'txt':
      case 'doc':
      case 'pdf':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: _actionButton('Claude', Icons.auto_awesome, () => _launchSession('claude'))),
            const SizedBox(width: 10),
            Expanded(child: _actionButton('Codex', Icons.psychology, () => _launchSession('codex'))),
            const SizedBox(width: 10),
            Expanded(child: _actionButton('Bash', Icons.terminal, () => _launchSession('bash'))),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF00D4AA)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
