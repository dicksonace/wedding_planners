import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _title = TextEditingController();
  final _bride = TextEditingController();
  final _groom = TextEditingController();
  final _date = TextEditingController();
  final _location = TextEditingController();
  final _region = TextEditingController();
  final _budget = TextEditingController();
  final _notes = TextEditingController();
  final Set<String> _ceremonies = {'traditional', 'reception'};
  bool _submitting = false;

  static const _ceremonyOptions = [
    'knocking',
    'engagement',
    'traditional',
    'church',
    'court',
    'reception',
  ];

  @override
  void dispose() {
    for (final c in [_title, _bride, _groom, _date, _location, _region, _budget, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      _date.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan title'), backgroundColor: AppColors.richRed),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<AppStore>().createWeddingPlan({
        'title': _title.text.trim(),
        'bride_name': _bride.text.trim().isEmpty ? null : _bride.text.trim(),
        'groom_name': _groom.text.trim().isEmpty ? null : _groom.text.trim(),
        'wedding_date': _date.text.trim().isEmpty ? null : _date.text.trim(),
        'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
        'region': _region.text.trim().isEmpty ? null : _region.text.trim(),
        'total_budget': _budget.text.trim().isEmpty ? null : double.tryParse(_budget.text.trim()),
        'ceremony_types': _ceremonies.toList(),
        'status': 'planning',
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Wedding Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set up your wedding so you can add guests, budget, and tasks.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Plan title *')),
            const SizedBox(height: 12),
            TextField(controller: _bride, decoration: const InputDecoration(labelText: 'Bride name')),
            const SizedBox(height: 12),
            TextField(controller: _groom, decoration: const InputDecoration(labelText: 'Groom name')),
            const SizedBox(height: 12),
            TextField(
              controller: _date,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Wedding date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Venue / location')),
            const SizedBox(height: 12),
            TextField(controller: _region, decoration: const InputDecoration(labelText: 'Region')),
            const SizedBox(height: 12),
            TextField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total budget (GHS)'),
            ),
            const SizedBox(height: 16),
            const Text('Ceremony types', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ceremonyOptions.map((type) {
                final selected = _ceremonies.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _ceremonies.add(type);
                    } else {
                      _ceremonies.remove(type);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create Plan', loading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

Future<bool?> openCreatePlanScreen(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
  );
}
