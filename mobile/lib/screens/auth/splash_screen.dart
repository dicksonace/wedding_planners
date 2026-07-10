import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = context.read<AppStore>();
      await store.init();
      if (!mounted) return;
      if (store.isLoggedIn) {
        context.go(store.user!.isVendor ? '/vendor' : '/couple');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.deepGreen, Color(0xFF00884F), AppColors.gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 56),
              SizedBox(height: 16),
              Text(
                'WedPlan Ghana',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text('Plan your perfect Ghanaian wedding', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
