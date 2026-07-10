import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _partner = TextEditingController();
  final _region = TextEditingController();
  final _business = TextEditingController();
  final _category = TextEditingController();
  String _role = 'couple';
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _phone, _partner, _region, _business, _category]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.richRed),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final payload = {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'password_confirmation': _confirm.text,
        'role': _role,
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        if (_role == 'couple') ...{
          'partner_name': _partner.text.trim().isEmpty ? null : _partner.text.trim(),
          'region': _region.text.trim().isEmpty ? null : _region.text.trim(),
        },
        if (_role == 'vendor') ...{
          'business_name': _business.text.trim(),
          'category': _category.text.trim(),
          'location': _region.text.trim().isEmpty ? null : _region.text.trim(),
        },
      };
      final email = await context.read<AppStore>().register(payload);
      if (mounted) context.go('/verify-email', extra: email);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: AppColors.deepGreen.withValues(alpha: 0.9), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We send a confirmation link to your email for security. You must verify before signing in.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'couple', label: Text('Couple'), icon: Icon(Icons.favorite)),
                ButtonSegment(value: 'vendor', label: Text('Vendor'), icon: Icon(Icons.storefront)),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 20),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address')),
            const SizedBox(height: 12),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
            const SizedBox(height: 12),
            if (_role == 'couple')
              TextField(controller: _partner, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Partner name (optional)')),
            if (_role == 'vendor') ...[
              TextField(controller: _business, decoration: const InputDecoration(labelText: 'Business name')),
              const SizedBox(height: 12),
              TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category (e.g. Catering)')),
            ],
            const SizedBox(height: 12),
            TextField(controller: _region, decoration: InputDecoration(labelText: _role == 'vendor' ? 'Location' : 'Region (optional)')),
            const SizedBox(height: 12),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 12),
            TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create Account', loading: _loading, onPressed: _register),
            TextButton(onPressed: () => context.pop(), child: const Text('Already have an account? Sign in')),
          ],
        ),
      ),
    );
  }
}
