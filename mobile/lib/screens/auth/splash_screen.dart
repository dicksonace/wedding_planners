import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../widgets/image_carousel.dart';

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
      await Future.wait([
        store.init(),
        Future.delayed(const Duration(milliseconds: 2800)),
      ]);
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
    return const Scaffold(
      body: FullScreenSlideshow(),
    );
  }
}
