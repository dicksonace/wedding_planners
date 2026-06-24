import 'package:flutter/material.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key, required this.weddingService, required this.onCreated});

  final WeddingService weddingService;
  final VoidCallback onCreated;

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brideController = TextEditingController();
  final _groomController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController(text: '50000');
  final _regionController = TextEditingController(text: 'Greater Accra');
  DateTime? _weddingDate;
  final Set<String> _ceremonies = {'traditional', 'church', 'reception'};
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await widget.weddingService.createPlan({
        'title': _titleController.text.trim(),
        'bride_name': _brideController.text.trim(),
        'groom_name': _groomController.text.trim(),
        'location': _locationController.text.trim(),
        'region': _regionController.text.trim(),
        'total_budget': double.tryParse(_budgetController.text) ?? 0,
        'ceremony_types': _ceremonies.toList(),
        if (_weddingDate != null) 'wedding_date': _weddingDate!.toIso8601String().split('T').first,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wedding plan created')));
        widget.onCreated();
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Wedding Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Plan Title'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _brideController, decoration: const InputDecoration(labelText: 'Bride Name')),
              const SizedBox(height: 12),
              TextFormField(controller: _groomController, decoration: const InputDecoration(labelText: 'Groom Name')),
              const SizedBox(height: 12),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 12),
              TextFormField(controller: _regionController, decoration: const InputDecoration(labelText: 'Region')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'Total Budget (GHS)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_weddingDate == null ? 'Select Wedding Date' : 'Date: ${_weddingDate!.toLocal()}'.split(' ').first),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    initialDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _weddingDate = picked);
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Ceremony Types', style: Theme.of(context).textTheme.titleMedium),
              ),
              Wrap(
                spacing: 8,
                children: [
                  'knocking',
                  'engagement',
                  'traditional',
                  'church',
                  'court',
                  'reception',
                ].map((type) {
                  final selected = _ceremonies.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _ceremonies.add(type);
                        } else {
                          _ceremonies.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
