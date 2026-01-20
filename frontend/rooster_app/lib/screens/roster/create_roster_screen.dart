import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/roster_provider.dart';

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
  String _endType = 'never'; // 'never', 'on_date', 'after_occurrences'
  DateTime? _endDate;
  int _occurrences = 10;

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
                label: const Text('One-time'),
                selected: _recurrence == 'once',
                onSelected: (selected) {
                  if (selected) setState(() => _recurrence = 'once');
                },
              ),
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

          // Day selector (only show if not one-time)
          if (_recurrence != 'once') ...[
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
          ],

          // Date selector (only show if one-time)
          if (_recurrence == 'once') ...[
            const Text(
              'Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _endDate != null
                    ? DateFormat('EEE, MMM d, y').format(_endDate!)
                    : 'Select date',
              ),
            ),
            const SizedBox(height: 24),
          ],

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

          // End condition (only show if recurring)
          if (_recurrence != 'once') ...[
            const Text(
              'Ends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('Never'),
              subtitle: const Text('Continues indefinitely (generates 7 events at a time)'),
              value: 'never',
              groupValue: _endType,
              onChanged: (value) {
                if (value != null) setState(() => _endType = value);
              },
            ),
            RadioListTile<String>(
              title: const Text('On date'),
              value: 'on_date',
              groupValue: _endType,
              onChanged: (value) {
                if (value != null) setState(() => _endType = value);
              },
            ),
            if (_endType == 'on_date') ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _endDate != null
                        ? DateFormat('EEE, MMM d, y').format(_endDate!)
                        : 'Select end date',
                  ),
                ),
              ),
            ],
            RadioListTile<String>(
              title: const Text('After number of occurrences'),
              value: 'after_occurrences',
              groupValue: _endType,
              onChanged: (value) {
                if (value != null) setState(() => _endType = value);
              },
            ),
            if (_endType == 'after_occurrences') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('After'),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        controller: TextEditingController(text: '$_occurrences'),
                        onChanged: (value) {
                          final num = int.tryParse(value);
                          if (num != null && num > 0) {
                            setState(() => _occurrences = num);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('occurrences'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
          ],

          // Create button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a roster name')),
                  );
                  return;
                }

                if (_recurrence == 'once' && _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a date')),
                  );
                  return;
                }

                final rosterProvider = Provider.of<RosterProvider>(context, listen: false);
                final success = await rosterProvider.createRoster(
                  teamId: widget.teamId ?? '1',
                  name: _nameController.text.trim(),
                  recurrence: _recurrence,
                  dayOfWeek: _selectedDay,
                  time: '09:00',
                  volunteersNeeded: _volunteersNeeded,
                );

                if (success && context.mounted) {
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
