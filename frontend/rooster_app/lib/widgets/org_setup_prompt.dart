import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/organisation_provider.dart';

/// A prompt card shown to admins with a personal (unnamed) organisation,
/// encouraging them to set up their organisation name.
class OrgSetupPrompt extends StatelessWidget {
  const OrgSetupPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orgProvider = Provider.of<OrganisationProvider>(context);

    if (authProvider.user?.isAdmin != true) return const SizedBox.shrink();

    final org = orgProvider.currentOrganisation;
    if (org == null || !org.isPersonal) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business_outlined, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Set up your organisation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Give your organisation a name to help members identify it.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    context.push('/organisations/${org.id}/settings');
                  },
                  child: const Text('Set Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
