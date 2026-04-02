import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final String label;

  const PremiumBadge({
    super.key,
    this.label = 'Premium',
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
    );
  }
}
