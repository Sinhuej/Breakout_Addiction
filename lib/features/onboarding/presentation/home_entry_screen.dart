import 'package:flutter/material.dart';

import '../../../core/constants/route_names.dart';
import '../../home/presentation/home_screen.dart';
import '../../widget/data/app_entry_repository.dart';
import '../data/onboarding_repository.dart';

class HomeEntryScreen extends StatefulWidget {
  const HomeEntryScreen({super.key});

  @override
  State<HomeEntryScreen> createState() => _HomeEntryScreenState();
}

class _HomeEntryScreenState extends State<HomeEntryScreen> {
  final OnboardingRepository _onboardingRepository = OnboardingRepository();
  final AppEntryRepository _appEntryRepository = AppEntryRepository();

  Widget? _child;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final state = await _onboardingRepository.getState();

    if (!mounted) {
      return;
    }

    if (!state.completed) {
      setState(() {
        _child = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, RouteNames.onboarding);
      });
      return;
    }

    final pending = await _appEntryRepository.consumePendingEntry();

    if (!mounted) {
      return;
    }

    if (pending == null || pending.routeName == RouteNames.home) {
      setState(() {
        _child = const HomeScreen();
      });
      return;
    }

    setState(() {
      _child = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, pending.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _child ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
  }
}
