import 'package:flutter/material.dart';

class SendInviteScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const SendInviteScreen({super.key, required this.member});

  @override
  State<SendInviteScreen> createState() => _SendInviteScreenState();
}

class _SendInviteScreenState extends State<SendInviteScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Invite ${widget.member['name']}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'They\'ll receive an email with a link to create their account and see their assignments.',
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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_emailController.text.trim().isNotEmpty) {
                    // TODO: Send invite
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invite sent to ${_emailController.text.trim()}'),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Send Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
