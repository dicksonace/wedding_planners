import 'package:flutter/material.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';
import 'package:wedplan_ghana/theme/app_theme.dart';

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

  Color _rsvpColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return AppTheme.richRed;
      default:
        return Colors.orange;
    }
  }

  Future<void> _addGuest() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String side = 'both';
    bool sendInvite = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool sendInviteLocal = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Guest'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (for invite)')),
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
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Send email invitation now'),
                    value: sendInviteLocal,
                    onChanged: (value) => setDialogState(() => sendInviteLocal = value ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  sendInvite = sendInviteLocal;
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true || nameController.text.trim().isEmpty) return;

    await widget.weddingService.addGuest(widget.planId, {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'side': side,
      'rsvp_status': 'pending',
      'send_invitation': sendInvite && emailController.text.trim().isNotEmpty,
    });
    await _load();
  }

  Future<void> _sendInvite(Map<String, dynamic> guest) async {
    if ((guest['email'] as String?)?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an email address before sending an invite.')),
      );
      return;
    }

    try {
      await widget.weddingService.sendGuestInvitation(widget.planId, guest['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation email sent. Guest can Accept or Decline from the email.')),
        );
      }
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _updateRsvp(Map<String, dynamic> guest, String status) async {
    await widget.weddingService.updateGuest(widget.planId, guest['id'] as int, {'rsvp_status': status});
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
                  Center(child: Text('No guests yet. Add guests and email them invitations.')),
                ],
              )
            : ListView.builder(
                itemCount: _guests.length,
                itemBuilder: (context, index) {
                  final guest = _guests[index] as Map<String, dynamic>;
                  final rsvp = guest['rsvp_status'].toString();
                  final invited = guest['invitation_sent_at'] != null;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(guest['name'].toString().substring(0, 1))),
                      title: Text(guest['name'].toString()),
                      subtitle: Text(
                        '${guest['side']} • ${guest['phone'] ?? 'No phone'}\n${guest['email'] ?? 'No email'}${invited ? ' • Invite sent' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            label: Text(rsvp),
                            backgroundColor: _rsvpColor(rsvp).withValues(alpha: 0.15),
                            labelStyle: TextStyle(color: _rsvpColor(rsvp)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.email_outlined),
                            tooltip: 'Send invitation email',
                            onPressed: () => _sendInvite(guest),
                          ),
                        ],
                      ),
                      onLongPress: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.check, color: Colors.green),
                                  title: const Text('Mark confirmed'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _updateRsvp(guest, 'confirmed');
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close, color: Colors.red),
                                  title: const Text('Mark declined'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _updateRsvp(guest, 'declined');
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.schedule),
                                  title: const Text('Mark pending'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _updateRsvp(guest, 'pending');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
