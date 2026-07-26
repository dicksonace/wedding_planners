import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> _showShareRegistration() async {
    final store = context.read<AppStore>();
    if (!store.hasPlan) return;

    try {
      final reg = store.guestRegistration ?? await store.fetchGuestRegistration();
      final url = reg['url']?.toString() ?? '';
      if (!mounted || url.isEmpty) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _RegistrationShareSheet(url: url, qrImageUrl: reg['qr_url']?.toString()),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    }
  }

  Future<void> _importGuestList() async {
    final store = context.read<AppStore>();
    if (!store.hasPlan) {
      final created = await openCreatePlanScreen(context);
      if (created != true || !mounted) return;
      await _load();
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt', 'xlsx', 'xls', 'docx', 'doc'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that file. Try exporting as CSV.'), backgroundColor: AppColors.richRed),
        );
      }
      return;
    }

    try {
      final response = await store.importGuests(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?.toString() ?? 'Guest list imported')),
      );
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    }
  }

  Future<void> _shareGuestInvite(Map<String, dynamic> guest) async {
    final store = context.read<AppStore>();
    try {
      var url = guest['invite_url']?.toString();
      if (url == null || url.isEmpty) {
        final link = await store.fetchGuestInviteLink(guest['id'] as int);
        url = link['invite_url']?.toString();
      }
      if (url == null || url.isEmpty) return;

      final name = guest['name']?.toString() ?? 'Guest';
      await Share.share(
        'Hi $name — please confirm your attendance here:\n$url',
        subject: 'Wedding invitation',
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      appBar: CoupleAppBar(
        title: 'Guest List',
        actions: store.hasPlan
            ? [
                IconButton(
                  tooltip: 'Import guest list',
                  icon: const Icon(Icons.upload_file_rounded),
                  onPressed: _importGuestList,
                ),
                IconButton(
                  tooltip: 'Share registration link',
                  icon: const Icon(Icons.qr_code_2_rounded),
                  onPressed: _showShareRegistration,
                ),
              ]
            : null,
      ),
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
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Guest registration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text(
                              'Share a link or QR code so guests can register and confirm attendance. Or upload an Excel (.xlsx), Word (.docx), or CSV guest list.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Share / QR',
                                    icon: Icons.qr_code_2_rounded,
                                    onPressed: _showShareRegistration,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _importGuestList,
                                    icon: const Icon(Icons.upload_file_rounded),
                                    label: const Text('Import list'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (store.guests.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: EmptyState(
                            icon: Icons.people_alt_rounded,
                            title: 'No guests yet',
                            subtitle: 'Add guests manually, import Excel/Word/CSV, or share your registration link.',
                          ),
                        )
                      else
                        ...store.guests.map(
                          (guest) => _GuestCard(
                            guest: guest,
                            onDelete: () async {
                              await store.deleteGuest(guest['id'] as int);
                            },
                            onShare: () => _shareGuestInvite(guest),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _RegistrationShareSheet extends StatelessWidget {
  const _RegistrationShareSheet({required this.url, this.qrImageUrl});

  final String url;
  final String? qrImageUrl;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Guest registration link', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Guests scan this QR or open the link to register and confirm attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.softGreen),
            ),
            child: QrImageView(
              data: url,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          if (qrImageUrl != null && qrImageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Backup QR image available online', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 16),
          SelectableText(url, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  onPressed: () => Share.share(
                    'You\'re invited — please register and confirm attendance:\n$url',
                    subject: 'Wedding guest registration',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.guest, required this.onDelete, required this.onShare});

  final Map<String, dynamic> guest;
  final VoidCallback onDelete;
  final VoidCallback onShare;

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
              tooltip: 'Share invite link',
              icon: const Icon(Icons.share_rounded, color: AppColors.deepGreen),
              onPressed: onShare,
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
