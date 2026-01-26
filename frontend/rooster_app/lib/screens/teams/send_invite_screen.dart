import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';

class SendInviteScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const SendInviteScreen({super.key, required this.member});

  @override
  State<SendInviteScreen> createState() => _SendInviteScreenState();
}

class _SendInviteScreenState extends State<SendInviteScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existingEmail = widget.member['email'] as String?;
    if (existingEmail != null && existingEmail.isNotEmpty) {
      _emailController.text = existingEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final memberName = widget.member['name'] as String? ?? 'Member';
    final memberId = widget.member['id'] as String?;
    final isInvited = widget.member['isInvited'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Invite'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite $memberName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isInvited
                  ? 'An invite was already sent. You can resend it if needed.'
                  : 'They\'ll receive an email with a link to create their account and see their assignments.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'john@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSending
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        if (email.isEmpty || memberId == null) {
                          setState(() {
                            _errorMessage = 'Please enter a valid email.';
                          });
                          return;
                        }

                        setState(() {
                          _isSending = true;
                          _errorMessage = null;
                        });

                        final success =
                            await teamProvider.sendInvite(memberId, email);

                        if (!mounted) return;

                        setState(() {
                          _isSending = false;
                          _errorMessage = success
                              ? null
                              : teamProvider.error ??
                                  'Failed to send invite. Please try again.';
                        });

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invite sent to $email'),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isInvited ? 'Resend Invite' : 'Send Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
