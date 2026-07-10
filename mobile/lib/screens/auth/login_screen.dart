import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await context.read<AppStore>().login(_email.text.trim(), _password.text);
      if (!mounted) return;
      final store = context.read<AppStore>();
      context.go(store.user!.isVendor ? '/vendor' : '/couple');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 && e.message.toLowerCase().contains('verify')) {
        context.go('/verify-email', extra: _email.text.trim());
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.deepGreen, Color(0xFF00884F)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.favorite, color: AppColors.gold, size: 36),
                    SizedBox(height: 12),
                    Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('Sign in to continue planning your wedding', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Sign In', loading: _loading, onPressed: _login),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('New here? Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
