import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedplan_ghana/models/user.dart';
import 'package:wedplan_ghana/screens/home_shell.dart';
import 'package:wedplan_ghana/screens/login_screen.dart';
import 'package:wedplan_ghana/screens/register_screen.dart';
import 'package:wedplan_ghana/screens/splash_screen.dart';
import 'package:wedplan_ghana/services/api_client.dart';
import 'package:wedplan_ghana/services/auth_service.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';
import 'package:wedplan_ghana/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(WedPlanApp(prefs: prefs));
}

class WedPlanApp extends StatefulWidget {
  const WedPlanApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<WedPlanApp> createState() => _WedPlanAppState();
}

class _WedPlanAppState extends State<WedPlanApp> {
  late final ApiClient _apiClient = ApiClient(widget.prefs);
  late final AuthService _authService = AuthService(_apiClient);
  late final WeddingService _weddingService = WeddingService(_apiClient);

  User? _user;
  bool _showRegister = false;
  bool _bootstrapping = true;

  Future<void> _bootstrap() async {
    final user = await _authService.currentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _bootstrapping = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WedPlan Ghana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _bootstrapping
          ? SplashScreen(onReady: _bootstrap)
          : _user == null
              ? _showRegister
                  ? RegisterScreen(
                      authService: _authService,
                      onRegistered: (user) => setState(() {
                        _user = user;
                        _showRegister = false;
                      }),
                      onLoginTap: () => setState(() => _showRegister = false),
                    )
                  : LoginScreen(
                      authService: _authService,
                      onLoggedIn: (user) => setState(() => _user = user),
                      onRegisterTap: () => setState(() => _showRegister = true),
                    )
              : HomeShell(
                  user: _user!,
                  authService: _authService,
                  weddingService: _weddingService,
                  onLogout: _logout,
                ),
    );
  }
}
