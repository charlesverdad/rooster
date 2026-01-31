import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/availability_provider.dart';
import '../../models/unavailability.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AvailabilityProvider>(
        context,
        listen: false,
      ).fetchUnavailabilities();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    ).fetchUnavailabilities();
  }

  Future<void> _showAddUnavailabilityDialog() async {
    DateTime? selectedDate;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mark Unavailable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select a date when you are not available:'),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate != null
                            ? DateFormat(
                                'EEEE, MMMM d, y',
                              ).format(selectedDate!)
                            : 'Tap to select date',
                        style: TextStyle(
                          color: selectedDate != null
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'e.g., Vacation, Work trip',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedDate == null
                  ? null
                  : () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedDate != null && mounted) {
      final provider = Provider.of<AvailabilityProvider>(
        context,
        listen: false,
      );
      final reason = reasonController.text.trim().isEmpty
          ? null
          : reasonController.text.trim();

      final success = await provider.markUnavailable(selectedDate!, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Marked as unavailable'
                  : provider.error ?? 'Failed to save',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }

    reasonController.dispose();
  }

  Future<void> _deleteUnavailability(Unavailability unavailability) async {
    final provider = Provider.of<AvailabilityProvider>(context, listen: false);

    final success = await provider.deleteUnavailability(unavailability.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Unavailability removed'
                : provider.error ?? 'Failed to delete',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AvailabilityProvider>(context);
    final unavailabilities = provider.unavailabilities;

    // Separate into upcoming and past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = unavailabilities
        .where((u) => u.date.isAfter(today) || u.date.isAtSameMomentAs(today))
        .toList();
    final past = unavailabilities.where((u) => u.date.isBefore(today)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Availability')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUnavailabilityDialog,
        icon: const Icon(Icons.event_busy),
        label: const Text('Mark Unavailable'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : unavailabilities.isEmpty
            ? _buildEmptyState()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (upcoming.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Upcoming Unavailability',
                      upcoming.length,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.map(
                      (unavailability) => _buildUnavailabilityCard(
                        context,
                        unavailability,
                        canDelete: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (past.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Past',
                      past.length,
                      Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    ...past.map(
                      (unavailability) => _buildUnavailabilityCard(
                        context,
                        unavailability,
                        canDelete: false,
                      ),
                    ),
                  ],
                  // Add padding at bottom for FAB
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No unavailability marked',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the button below to mark dates\nwhen you are not available',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailabilityCard(
    BuildContext context,
    Unavailability unavailability, {
    required bool canDelete,
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        unavailability.date.year == today.year &&
        unavailability.date.month == today.month &&
        unavailability.date.day == today.day;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_busy, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dateFormat.format(unavailability.date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (unavailability.reason != null &&
                      unavailability.reason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      unavailability.reason!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                onPressed: () => _deleteUnavailability(unavailability),
              ),
          ],
        ),
      ),
    );

    if (!canDelete) {
      return card;
    }

    return Dismissible(
      key: Key(unavailability.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteUnavailability(unavailability),
      child: card,
    );
  }
}
