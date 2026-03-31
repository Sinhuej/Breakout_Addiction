import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';
import '../../privacy/domain/lock_scope.dart';
import '../../privacy/presentation/protected_route_gate.dart';
import '../data/onboarding_repository.dart';
import 'onboarding_screen.dart';

class HomeEntryScreen extends StatelessWidget {
  const HomeEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = OnboardingRepository();

    return FutureBuilder<bool>(
      future: repository.isComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completed = snapshot.data ?? false;
        if (!completed) {
          return const OnboardingScreen();
        }

        return const ProtectedRouteGate(
          scope: LockScope.app,
          child: HomeScreen(),
        );
      },
    );
  }
}
