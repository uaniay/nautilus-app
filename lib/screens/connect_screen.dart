import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _loginWithPassword() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (url.isEmpty) {
      setState(() => _error = 'Please enter server address');
      return;
    }
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = context.read<ConnectionService>();
    final success = await service.login(url, username, password);

    if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _error = 'Login failed — check credentials';
      });
    }
  }

  Future<void> _connectWithToken() async {
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
    _usernameController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
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
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 400,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Token'),
                  ],
                  indicatorColor: const Color(0xFF00D4AA),
                  labelColor: const Color(0xFF00D4AA),
                  unselectedLabelColor: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 400,
                height: 140,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outlined),
                          ),
                          onSubmitted: (_) => _loginWithPassword(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                          obscureText: true,
                          onSubmitted: (_) => _loginWithPassword(),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            labelText: 'JWT Token',
                            hintText: 'Paste your token here...',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                          obscureText: true,
                          onSubmitted: (_) => _connectWithToken(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_tabController.index == 0) {
                            _loginWithPassword();
                          } else {
                            _connectWithToken();
                          }
                        },
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
