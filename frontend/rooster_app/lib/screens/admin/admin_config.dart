import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminConfig extends StatefulWidget {
  const AdminConfig({super.key});

  @override
  State<AdminConfig> createState() => _AdminConfigState();
}

class _AdminConfigState extends State<AdminConfig> {
  bool _emailEnabled = true;
  bool _googleEnabled = false;
  final _googleClientIdController = TextEditingController();
  bool _dirty = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchConfig();
      context.read<AdminProvider>().fetchDashboardStats();
    });
  }

  @override
  void dispose() {
    _googleClientIdController.dispose();
    super.dispose();
  }

  void _initFromConfig(Map<String, dynamic> config) {
    if (_initialized) return;
    _emailEnabled = config['email_enabled'] == true;
    _googleEnabled = config['google_enabled'] == true;
    _googleClientIdController.text =
        config['google_client_id'] as String? ?? '';
    _initialized = true;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final provider = context.read<AdminProvider>();
    final data = <String, dynamic>{
      'email_enabled': _emailEnabled,
      'google_enabled': _googleEnabled,
      'google_client_id': _googleClientIdController.text.trim(),
    };
    final success = await provider.updateConfig(data);
    if (success && mounted) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Configuration saved.')));
    } else if (mounted && provider.configError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${provider.configError}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.loadingConfig && provider.config == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.config != null) {
          _initFromConfig(provider.config!);
        }

        final stats = provider.dashboardStats;
        final authConfig = stats?['auth_config'] as Map<String, dynamic>? ?? {};
        final pushSubs =
            stats?['push_subscriptions'] as Map<String, dynamic>? ?? {};

        final allDisabled = !_emailEnabled && !_googleEnabled;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Card 1: Authentication Methods
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Methods',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    if (allDisabled) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Warning: All authentication methods are disabled. '
                                'Users will be unable to log in.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SwitchListTile(
                      title: const Text('Email / Password Login'),
                      value: _emailEnabled,
                      onChanged: (value) {
                        setState(() => _emailEnabled = value);
                        _markDirty();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Google Sign-In'),
                      value: _googleEnabled,
                      onChanged: (value) {
                        setState(() => _googleEnabled = value);
                        _markDirty();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _googleClientIdController,
                      enabled: _googleEnabled,
                      decoration: const InputDecoration(
                        labelText: 'Google Client ID',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _dirty && !provider.savingConfig
                          ? _save
                          : null,
                      child: provider.savingConfig
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card 2: Email Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Delivery',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _ReadOnlyRow(
                      label: 'Provider',
                      value: authConfig['email_provider'] as String? ?? '-',
                    ),
                    _ReadOnlyRow(
                      label: 'Status',
                      value: authConfig['email_configured'] == true
                          ? 'Configured'
                          : 'Not Configured',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Email configuration is managed via environment variables.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card 3: Push Notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _ReadOnlyRow(
                      label: 'VAPID Keys',
                      value: authConfig['push_configured'] == true
                          ? 'Configured'
                          : 'Not Configured',
                    ),
                    _ReadOnlyRow(
                      label: 'Active Subscriptions',
                      value: '${pushSubs['total'] ?? '-'}',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'VAPID keys are managed via environment variables.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
