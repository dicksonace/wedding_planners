import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_plan_screen.dart';
import 'home_shell.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key});

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = context.read<AppStore>();
    await store.refreshDashboard();
    if (store.hasPlan) await store.fetchGuests();
  }

  Future<void> _openAddGuest() async {
    final store = context.read<AppStore>();
    if (!store.hasPlan) {
      final created = await openCreatePlanScreen(context);
      if (created == true && mounted) await _load();
      return;
    }

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddGuestSheet(),
    );
    if (added == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      appBar: const CoupleAppBar(title: 'Guest List'),
      floatingActionButton: AppAddFab(
        tooltip: store.hasPlan ? 'Add guest' : 'Create plan',
        onPressed: _openAddGuest,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _load,
        child: !store.hasPlan
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  PlanRequiredBanner(onCreatePlan: () async {
                    final created = await openCreatePlanScreen(context);
                    if (created == true && mounted) await _load();
                  }),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Create Wedding Plan',
                    icon: Icons.add,
                    onPressed: () async {
                      final created = await openCreatePlanScreen(context);
                      if (created == true && mounted) await _load();
                    },
                  ),
                ],
              )
            : store.guestsLoading
                ? const Center(child: CircularProgressIndicator())
                : store.guests.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          const SizedBox(height: 40),
                          const EmptyState(
                            icon: Icons.people_alt_rounded,
                            title: 'No guests yet',
                            subtitle: 'Add family and friends to your wedding guest list.',
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Add Guest',
                            icon: Icons.person_add,
                            onPressed: _openAddGuest,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: store.guests.length,
                        itemBuilder: (context, i) {
                          final guest = store.guests[i];
                          return _GuestCard(
                            guest: guest,
                            onDelete: () async {
                              await store.deleteGuest(guest['id'] as int);
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.guest, required this.onDelete});

  final Map<String, dynamic> guest;
  final VoidCallback onDelete;

  Color _rsvpColor(String? status) {
    switch (status) {
      case 'confirmed':
        return AppColors.deepGreen;
      case 'declined':
        return AppColors.richRed;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = guest['rsvp_status'] as String? ?? 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.softGreen,
              child: Text(
                (guest['name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guest['name'] as String? ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (guest['email'] != null)
                    Text(guest['email'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  if (guest['phone'] != null)
                    Text(guest['phone'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _rsvpColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'RSVP: $status',
                      style: TextStyle(color: _rsvpColor(status), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.richRed),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove guest?'),
                    content: Text('Remove ${guest['name']} from your guest list?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                    ],
                  ),
                );
                if (confirm == true) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGuestSheet extends StatefulWidget {
  const _AddGuestSheet();

  @override
  State<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends State<_AddGuestSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _side = 'both';
  String _rsvp = 'pending';
  bool _plusOne = false;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      await context.read<AppStore>().addGuest({
        'name': _name.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'side': _side,
        'rsvp_status': _rsvp,
        'plus_one': _plusOne,
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Guest', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name *')),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _side,
            decoration: const InputDecoration(labelText: 'Side'),
            items: const [
              DropdownMenuItem(value: 'bride', child: Text("Bride's side")),
              DropdownMenuItem(value: 'groom', child: Text("Groom's side")),
              DropdownMenuItem(value: 'both', child: Text('Both')),
            ],
            onChanged: (v) => setState(() => _side = v ?? 'both'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _rsvp,
            decoration: const InputDecoration(labelText: 'RSVP status'),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
              DropdownMenuItem(value: 'declined', child: Text('Declined')),
            ],
            onChanged: (v) => setState(() => _rsvp = v ?? 'pending'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Plus one'),
            value: _plusOne,
            onChanged: (v) => setState(() => _plusOne = v),
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Save Guest', loading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}
