import 'package:flutter/material.dart';
import 'package:wedplan_ghana/models/user.dart';
import 'package:wedplan_ghana/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.authService,
    required this.onRegistered,
    required this.onLoginTap,
  });

  final AuthService authService;
  final ValueChanged<User> onRegistered;
  final VoidCallback onLoginTap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _partnerController = TextEditingController();
  final _regionController = TextEditingController(text: 'Greater Accra');
  final _businessController = TextEditingController();
  String _role = 'couple';
  String _vendorCategory = 'Catering';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _passwordController.text,
        'role': _role,
        'phone': _phoneController.text.trim(),
        'region': _regionController.text.trim(),
        if (_role == 'couple') 'partner_name': _partnerController.text.trim(),
        if (_role == 'vendor') ...{
          'business_name': _businessController.text.trim(),
          'category': _vendorCategory,
        },
      };

      final user = await widget.authService.register(payload);
      widget.onRegistered(user);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'couple', label: Text('Couple')),
                    ButtonSegment(value: 'vendor', label: Text('Vendor')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (value) => setState(() => _role = value.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: _role == 'couple' ? 'Your Name' : 'Contact Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value == null || value.length < 8 ? 'Minimum 8 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regionController,
                  decoration: const InputDecoration(labelText: 'Region'),
                ),
                if (_role == 'couple') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _partnerController,
                    decoration: const InputDecoration(labelText: 'Partner Name'),
                  ),
                ],
                if (_role == 'vendor') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessController,
                    decoration: const InputDecoration(labelText: 'Business Name'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _vendorCategory,
                    decoration: const InputDecoration(labelText: 'Service Category'),
                    items: const [
                      'Catering',
                      'Photography',
                      'Decoration',
                      'Venue',
                      'DJ / Music',
                    ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                    onChanged: (value) => setState(() => _vendorCategory = value ?? _vendorCategory),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register'),
                  ),
                ),
                TextButton(onPressed: widget.onLoginTap, child: const Text('Already have an account? Login')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
