import 'package:flutter/material.dart';

class ShortcutBar extends StatefulWidget {
  final void Function(String data) onSend;

  const ShortcutBar({super.key, required this.onSend});

  @override
  State<ShortcutBar> createState() => _ShortcutBarState();
}

class _ShortcutBarState extends State<ShortcutBar> {
  bool _ctrlActive = false;

  void _sendKey(String key) {
    if (_ctrlActive) {
      final code = key.toUpperCase().codeUnitAt(0) - 64;
      if (code > 0 && code < 32) {
        widget.onSend(String.fromCharCode(code));
      }
      setState(() => _ctrlActive = false);
    } else {
      widget.onSend(key);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _shortcutBtn('Ctrl+C', () => widget.onSend('\x03')),
            _shortcutBtn('Ctrl+D', () => widget.onSend('\x04')),
            _shortcutBtn('Ctrl+Z', () => widget.onSend('\x1a')),
            _shortcutBtn('Ctrl+L', () => widget.onSend('\x0c')),
            _shortcutBtn('↑', () => widget.onSend('\x1b[A')),
            _shortcutBtn('↓', () => widget.onSend('\x1b[B')),
            _shortcutBtn('←', () => widget.onSend('\x1b[D')),
            _shortcutBtn('→', () => widget.onSend('\x1b[C')),
            _shortcutBtn('HOME', () => widget.onSend('\x1b[H')),
            _shortcutBtn('END', () => widget.onSend('\x1b[F')),
            _shortcutBtn('PGUP', () => widget.onSend('\x1b[5~')),
            _shortcutBtn('PGDN', () => widget.onSend('\x1b[6~')),
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
