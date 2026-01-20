import 'package:flutter/material.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('My Teams - Coming Soon'),
      ),
    );
  }
}
