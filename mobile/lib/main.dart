import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'store/app_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  final router = AppRouter.create(store);
  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: WedPlanApp(router: router),
    ),
  );
}

class WedPlanApp extends StatelessWidget {
  const WedPlanApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WedPlan Ghana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
