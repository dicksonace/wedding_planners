import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _partner;
  late final TextEditingController _region;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppStore>().user!;
    _name = TextEditingController(text: user.name);
    _phone = TextEditingController(text: user.phone ?? '');
    _partner = TextEditingController(text: user.partnerName ?? '');
    _region = TextEditingController(text: user.region ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _partner.dispose();
    _region.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AppStore>().updateProfile({
        'name': _name.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'partner_name': _partner.text.trim().isEmpty ? null : _partner.text.trim(),
        'region': _region.text.trim().isEmpty ? null : _region.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStore>().user!;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user.email}', style: const TextStyle(color: AppColors.textMuted)),
                Text('Role: ${user.role}', style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          if (user.isCouple) ...[
            const SizedBox(height: 12),
            TextField(controller: _partner, decoration: const InputDecoration(labelText: 'Partner name')),
          ],
          const SizedBox(height: 12),
          TextField(controller: _region, decoration: const InputDecoration(labelText: 'Region')),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save Profile', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
