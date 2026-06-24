import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:idr_dart_sdk/idr_dart_sdk.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IdrAgentDemoApp());
}

class IdrAgentDemoApp extends StatelessWidget {
  const IdrAgentDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'idr.to Agent Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class SecureIdrTokenStorage implements IdrTokenStorage {
  SecureIdrTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  IdrClient? _client;
  final _log = <String>[];

  final _apiUrlCtrl = TextEditingController(text: 'https://idr.to');
  final _entityCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _joinKeyCtrl = TextEditingController();
  final _connectUriCtrl = TextEditingController(
    text: 'idrto:user@example.com/laptop/22',
  );
  final _localPortCtrl = TextEditingController(text: '0');

  IdrAgentMode _mode = IdrAgentMode.hybrid;
  bool _agentRunning = false;
  bool _busy = false;

  @override
  void dispose() {
    _client?.dispose();
    _apiUrlCtrl.dispose();
    _entityCtrl.dispose();
    _hostCtrl.dispose();
    _passwordCtrl.dispose();
    _tokenCtrl.dispose();
    _joinKeyCtrl.dispose();
    _connectUriCtrl.dispose();
    _localPortCtrl.dispose();
    super.dispose();
  }

  void _append(String line) {
    setState(() {
      _log.insert(0, '${DateTime.now().toIso8601String()}  $line');
      if (_log.length > 80) _log.removeLast();
    });
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _append('$label failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<IdrClient> _ensureClient() async {
    if (_client != null) return _client!;
    final dir = await getApplicationSupportDirectory();
    final stateDir = '${dir.path}/idr';
    final libraryPath = Platform.environment['IDR_SDK_LIB'];
    _client = await IdrClient.open(
      IdrConfig(
        apiBaseUrl: _apiUrlCtrl.text.trim(),
        stateDir: stateDir,
        library: libraryPath == null || libraryPath.isEmpty
            ? const DefaultIdrNativeLibrary()
            : DefaultIdrNativeLibrary(libraryPath: libraryPath),
      ),
      tokenStorage: SecureIdrTokenStorage(const FlutterSecureStorage()),
    );
    _append('SDK ${_client!.version} opened (state: $stateDir)');
    _client!.events.listen((e) => _append('event: $e'));
    return _client!;
  }

  Future<void> _applyProfile() async {
    await _run('configure', () async {
      final client = await _ensureClient();
      final result = await client.configureAgent(IdrAgentProfile(
        mode: _mode,
        entityId: _entityCtrl.text.trim(),
        host: _hostCtrl.text.trim(),
        sourceHost: _hostCtrl.text.trim(),
      ));
      _append('configured: ${result.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('idr.to Agent Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Setup'),
              Tab(text: 'Auth'),
              Tab(text: 'Target'),
              Tab(text: 'Source'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _setupTab(),
            _authTab(),
            _targetTab(),
            _sourceTab(),
          ],
        ),
        bottomNavigationBar: _logPanel(),
      ),
    );
  }

  Widget _setupTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Tenant control plane and agent profile (maps to idr-agent.toml).',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiUrlCtrl,
          decoration: const InputDecoration(
            labelText: 'API base URL',
            hintText: 'https://connect.scomm.ai',
          ),
        ),
        TextField(
          controller: _entityCtrl,
          decoration: const InputDecoration(labelText: 'Entity ID'),
        ),
        TextField(
          controller: _hostCtrl,
          decoration: const InputDecoration(labelText: 'Host name (this device)'),
        ),
        DropdownButtonFormField<IdrAgentMode>(
          // ignore: deprecated_member_use
          value: _mode,
          decoration: const InputDecoration(labelText: 'Agent mode'),
          items: IdrAgentMode.values
              .map((m) => DropdownMenuItem(value: m, child: Text(m.value)))
              .toList(),
          onChanged: _busy
              ? null
              : (v) => setState(() => _mode = v ?? IdrAgentMode.hybrid),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _applyProfile,
          child: const Text('Save profile'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run('health', () async {
                    final client = await _ensureClient();
                    final h = await client.apiHealth();
                    _append('api health: ${h.ok}');
                  }),
          child: const Text('Check API health'),
        ),
      ],
    );
  }

  Widget _authTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'CLI password'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run('login', () async {
                    final client = await _ensureClient();
                    await client.loginWithPassword(
                      entityId: _entityCtrl.text.trim(),
                      password: _passwordCtrl.text,
                    );
                    _append('password login ok');
                  }),
          child: const Text('Login with password'),
        ),
        const Divider(height: 32),
        TextField(
          controller: _tokenCtrl,
          decoration: const InputDecoration(
            labelText: 'Bearer / OIDC token (SSO)',
          ),
          maxLines: 3,
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run('token login', () async {
                    final client = await _ensureClient();
                    await client.loginWithToken(_tokenCtrl.text.trim());
                    _append('token stored');
                  }),
          child: const Text('Login with token'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run('auth status', () async {
                    final client = await _ensureClient();
                    final s = await client.authStatus();
                    _append('auth: ${s.data}');
                  }),
          child: const Text('Auth status'),
        ),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run('logout', () async {
                    final client = await _ensureClient();
                    await client.logout();
                    _append('logged out');
                  }),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  Widget _targetTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Target / hybrid: register this device (join) and run the inbound agent.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _joinKeyCtrl,
          decoration: const InputDecoration(
            labelText: 'Optional join key',
          ),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run('join', () async {
                    final client = await _ensureClient();
                    final key = _joinKeyCtrl.text.trim();
                    final result = await client.joinDevice(IdrJoinOptions(
                      hostName: _hostCtrl.text.trim(),
                      joinKey: key.isEmpty ? null : key,
                    ));
                    _append('join: ${result.data}');
                  }),
          child: const Text('Device join'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy || _agentRunning
              ? null
              : () => _run('agent start', () async {
                    final client = await _ensureClient();
                    await client.startAgent();
                    setState(() => _agentRunning = true);
                    _append('agent started');
                  }),
          child: const Text('Start agent (target)'),
        ),
        OutlinedButton(
          onPressed: _busy || !_agentRunning
              ? null
              : () => _run('agent stop', () async {
                    final client = await _ensureClient();
                    await client.stopAgent();
                    setState(() => _agentRunning = false);
                    _append('agent stopped');
                  }),
          child: const Text('Stop agent'),
        ),
      ],
    );
  }

  Widget _sourceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Source / hybrid: outbound connect (idr connect equivalent).',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _connectUriCtrl,
          decoration: const InputDecoration(
            labelText: 'idrto URI',
            hintText: 'idrto:entity/host/22',
          ),
        ),
        TextField(
          controller: _localPortCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Local TCP port (0 = no listener)',
          ),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run('connect', () async {
                    final client = await _ensureClient();
                    final port = int.tryParse(_localPortCtrl.text) ?? 0;
                    final session = await client.connect(
                      _connectUriCtrl.text.trim(),
                      options: IdrConnectOptions(
                        localPort: port,
                        holdSeconds: 0,
                      ),
                    );
                    _append(
                      'connected ${session.entityId}/${session.host}/${session.service} '
                      'session=${session.signalSession}',
                    );
                  }),
          child: const Text('Connect'),
        ),
      ],
    );
  }

  Widget _logPanel() {
    return Material(
      elevation: 8,
      child: SizedBox(
        height: 160,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: _log.isEmpty
              ? [const Text('Log output…')]
              : _log.map(Text.new).toList(),
        ),
      ),
    );
  }
}
