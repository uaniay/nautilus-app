import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final service = context.read<ConnectionService>();
    await service.loadSavedSettings();
    if (service.serverUrl.isNotEmpty) {
      _urlController.text = service.serverUrl;
    }
    if (service.token.isNotEmpty) {
      _tokenController.text = service.token;
    }
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    if (url.isEmpty) {
      setState(() => _error = 'Please enter server address');
      return;
    }
    if (token.isEmpty) {
      setState(() => _error = 'Please enter token');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = context.read<ConnectionService>();
    final success = await service.connect(url, token);

    if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _error = 'Connection failed — check address and token';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.terminal,
                size: 64,
                color: Color(0xFF00D4AA),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nautilus',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D4AA),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Remote CLI Terminal',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Server Address',
                    hintText: 'http://192.168.1.100:8080',
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _connect(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'JWT Token',
                    hintText: 'Paste your token here...',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  obscureText: true,
                  onSubmitted: (_) => _connect(),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _connect,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Connect',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
