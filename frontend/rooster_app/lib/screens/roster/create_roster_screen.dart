import 'package:flutter/material.dart';

class CreateRosterScreen extends StatefulWidget {
  final String? teamId;

  const CreateRosterScreen({super.key, this.teamId});

  @override
  State<CreateRosterScreen> createState() => _CreateRosterScreenState();
}

class _CreateRosterScreenState extends State<CreateRosterScreen> {
  final _nameController = TextEditingController();
  String _recurrence = 'weekly';
  int _selectedDay = 0; // Sunday
  int _volunteersNeeded = 2;
  String _generateFor = '3_months';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Roster'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Roster Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Roster Name',
              hintText: 'Sunday Service',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          // Team (pre-filled if from team context)
          DropdownButtonFormField<String>(
            value: widget.teamId ?? '1',
            decoration: const InputDecoration(
              labelText: 'Team',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '1', child: Text('📹 Media Team')),
              DropdownMenuItem(value: '2', child: Text('🎵 Worship Team')),
            ],
            onChanged: (value) {},
          ),
          const SizedBox(height: 24),

          // Repeats
          const Text(
            'Repeats',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Weekly'),
                selected: _recurrence == 'weekly',
                onSelected: (selected) {
                  if (selected) setState(() => _recurrence = 'weekly');
                },
              ),
              ChoiceChip(
                label: const Text('Bi-weekly'),
                selected: _recurrence == 'biweekly',
                onSelected: (selected) {
                  if (selected) setState(() => _recurrence = 'biweekly');
                },
              ),
              ChoiceChip(
                label: const Text('Monthly'),
                selected: _recurrence == 'monthly',
                onSelected: (selected) {
                  if (selected) setState(() => _recurrence = 'monthly');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Day selector
          const Text(
            'Day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDayButton('S', 0),
              _buildDayButton('M', 1),
              _buildDayButton('T', 2),
              _buildDayButton('W', 3),
              _buildDayButton('T', 4),
              _buildDayButton('F', 5),
              _buildDayButton('S', 6),
            ],
          ),
          const SizedBox(height: 24),

          // Volunteers needed
          const Text(
            'Volunteers needed',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _volunteersNeeded > 1
                    ? () => setState(() => _volunteersNeeded--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
              ),
              const SizedBox(width: 24),
              Text(
                '$_volunteersNeeded',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _volunteersNeeded < 10
                    ? () => setState(() => _volunteersNeeded++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Generate for
          DropdownButtonFormField<String>(
            value: _generateFor,
            decoration: const InputDecoration(
              labelText: 'Generate for next',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '1_month', child: Text('1 month')),
              DropdownMenuItem(value: '3_months', child: Text('3 months')),
              DropdownMenuItem(value: '6_months', child: Text('6 months')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _generateFor = value);
            },
          ),
          const SizedBox(height: 32),

          // Create button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  // TODO: Create roster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Roster "${_nameController.text.trim()}" created'),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(String label, int day) {
    final isSelected = _selectedDay == day;
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
