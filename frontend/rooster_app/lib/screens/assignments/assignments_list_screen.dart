import 'package:flutter/material.dart';

class AssignmentsListScreen extends StatelessWidget {
  const AssignmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search/filter
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Assignments List - Coming Soon'),
      ),
    );
  }
}
