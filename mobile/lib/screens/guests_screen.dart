import 'package:flutter/material.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key, required this.weddingService, required this.planId});

  final WeddingService weddingService;
  final int planId;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  List<dynamic> _guests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _guests = await widget.weddingService.guests(widget.planId);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addGuest() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String side = 'both';
    String rsvp = 'pending';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Guest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            DropdownButtonFormField<String>(
              initialValue: side,
              items: const [
                DropdownMenuItem(value: 'bride', child: Text('Bride side')),
                DropdownMenuItem(value: 'groom', child: Text('Groom side')),
                DropdownMenuItem(value: 'both', child: Text('Both')),
              ],
              onChanged: (value) => side = value ?? side,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || nameController.text.trim().isEmpty) return;

    await widget.weddingService.addGuest(widget.planId, {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'side': side,
      'rsvp_status': rsvp,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGuest,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Guest'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _guests.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No guests added yet.')),
                ],
              )
            : ListView.builder(
                itemCount: _guests.length,
                itemBuilder: (context, index) {
                  final guest = _guests[index] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(guest['name'].toString().substring(0, 1))),
                      title: Text(guest['name'].toString()),
                      subtitle: Text('${guest['side']} • ${guest['phone'] ?? 'No phone'}'),
                      trailing: Chip(label: Text(guest['rsvp_status'].toString())),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
