import 'package:flutter/material.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final dynamic assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment'),
      ),
      body: const Center(
        child: Text('Assignment Detail - Coming Soon'),
      ),
    );
  }
}
