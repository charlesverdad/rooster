import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A back button that pops the current route if possible,
/// or navigates to the home screen if there's nothing to pop back to
/// (e.g., when the user arrived via deep link or push notification).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/');
        }
      },
    );
  }
}
