import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@example.com');
  final _passCtrl = TextEditingController(text: 'admin123');
  late final TextEditingController _serverCtrl;
  bool _isServerConfigExpanded = false;
  String? _serverPingStatus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _serverCtrl = TextEditingController(text: provider.serverUrl);
  }

  void _testServerConnection() async {
    final provider = context.read<AppProvider>();
    provider.setServerUrl(_serverCtrl.text.trim());
    setState(() => _serverPingStatus = 'Testing connection...');
    final ok = await provider.pingServer();
    if (mounted) {
      setState(() {
        _serverPingStatus = ok ? '✅ Connected to server!' : '❌ Cannot reach server at this address.';
      });
    }
  }

  void _submit() async {
    final provider = context.read<AppProvider>();
    provider.setServerUrl(_serverCtrl.text.trim());
    final success = await provider.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Login failed. Please check server IP and credentials.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.sync_alt_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ShiftOps Portal',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Handover & Task Management',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Server Configuration Accordion
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isServerConfigExpanded = !_isServerConfigExpanded),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_rounded, size: 18, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Server: ${_serverCtrl.text}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              _isServerConfigExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      if (_isServerConfigExpanded) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _serverCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Backend Server URL',
                            hintText: 'http://172.20.60.136:5050',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF4F46E5)),
                              onPressed: _testServerConnection,
                            ),
                          ),
                        ),
                        if (_serverPingStatus != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _serverPingStatus!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _serverPingStatus!.contains('✅') ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 22),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Quick Demo Logins:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _emailCtrl.text = 'admin@example.com';
                        _passCtrl.text = 'admin123';
                        _submit();
                      },
                      child: const Text('Admin (Ops Lead)'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _emailCtrl.text = 'john@example.com';
                        _passCtrl.text = 'employee123';
                        _submit();
                      },
                      child: const Text('John (EMP-101)'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _emailCtrl.text = 'sarah@example.com';
                        _passCtrl.text = 'employee123';
                        _submit();
                      },
                      child: const Text('Sarah (EMP-102)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
