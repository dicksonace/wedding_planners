import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../store/app_store.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/couple/home_shell.dart';
import '../screens/vendor/vendor_shell.dart';

class AppRouter {
  static GoRouter create(AppStore store) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: store,
      redirect: (context, state) {
        final loggedIn = store.isLoggedIn;
        final loc = state.matchedLocation;
        final isAuth = loc == '/' ||
            loc.startsWith('/login') ||
            loc.startsWith('/register') ||
            loc.startsWith('/verify-email');

        if (!store.isInitialized && loc != '/') return '/';
        if (!loggedIn && !isAuth) return '/login';
        if (loggedIn && (loc == '/login' || loc == '/register' || loc == '/verify-email' || loc == '/')) {
          return store.user!.isVendor ? '/vendor' : '/couple';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: '/verify-email',
          builder: (_, state) => VerifyEmailScreen(email: state.extra as String? ?? ''),
        ),
        GoRoute(path: '/couple', builder: (_, __) => const CoupleHomeShell()),
        GoRoute(path: '/vendor', builder: (_, __) => const VendorShell()),
      ],
    );
  }
}

String homeRouteForUser(AppStore store) {
  if (store.user?.isVendor ?? false) return '/vendor';
  return '/couple';
}

extension GoContext on BuildContext {
  void goHome(AppStore store) => go(homeRouteForUser(store));
}
