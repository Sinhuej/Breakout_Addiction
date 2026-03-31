import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';

class BreakoutApp extends StatelessWidget {
  const BreakoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breakout Addiction',
      debugShowCheckedModeBanner: false,
      theme: buildBreakoutTheme(),
      initialRoute: RouteNames.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
