import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assignment_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssignmentProvider>(context, listen: false).fetchMyAssignments();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<AssignmentProvider>(context, listen: false).fetchMyAssignments();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: assignmentProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : assignmentProvider.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          assignmentProvider.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : assignmentProvider.assignments.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Icon(Icons.event_available, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No upcoming assignments',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: assignmentProvider.assignments.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${authProvider.user?.name ?? "User"}!',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your Upcoming Assignments',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            );
                          }

                          final assignment = assignmentProvider.assignments[index - 1];
                          final dateFormat = DateFormat('EEEE, MMMM d, y');
                          final isToday = DateTime.now().difference(assignment.date).inDays == 0;
                          final isPast = assignment.date.isBefore(DateTime.now());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPast
                                    ? Colors.grey
                                    : isToday
                                        ? Colors.orange
                                        : Theme.of(context).primaryColor,
                                child: Icon(
                                  isPast ? Icons.check : Icons.event,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                assignment.rosterName ?? 'Assignment',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(dateFormat.format(assignment.date)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Status: ${assignment.status.toUpperCase()}',
                                    style: TextStyle(
                                      color: assignment.status == 'confirmed'
                                          ? Colors.green
                                          : assignment.status == 'declined'
                                              ? Colors.red
                                              : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isToday
                                  ? Chip(
                                      label: const Text('TODAY'),
                                      backgroundColor: Colors.orange,
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
