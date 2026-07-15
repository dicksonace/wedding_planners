import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().refreshDashboard();
    });
  }

  Future<void> _respond(Map<String, dynamic> request, String status) async {
    try {
      await context.read<AppStore>().respondToVendorRequest(
            request['id'] as int,
            status: status,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${status == 'accepted' ? 'accepted' : 'declined'}.')),
        );
      }
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
    final data = store.vendorDashboard;
    final stats = data?['stats'] as Map<String, dynamic>?;
    final pending = (data?['pending_requests'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    final recent = (data?['recent_requests'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        actions: const [ProfileMenuButton()],
      ),
      body: RefreshIndicator(
        onRefresh: store.refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GradientHeader(
              title: store.user?.name ?? 'Vendor',
              subtitle: data?['vendor']?['business_name']?.toString() ?? 'Manage client requests',
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
              children: [
                StatTile(icon: Icons.inbox, label: 'Total requests', value: '${stats?['total_requests'] ?? 0}'),
                StatTile(icon: Icons.hourglass_top, label: 'Pending', value: '${stats?['pending_requests'] ?? 0}', color: AppColors.gold),
                StatTile(icon: Icons.check_circle, label: 'Accepted', value: '${stats?['accepted_requests'] ?? 0}'),
                StatTile(icon: Icons.cancel, label: 'Declined', value: '${stats?['declined_requests'] ?? 0}', color: AppColors.richRed),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Pending requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              const AppCard(
                child: Text('No pending requests right now.', style: TextStyle(color: AppColors.textMuted)),
              )
            else
              ...pending.map((item) => _RequestCard(
                    request: item,
                    showActions: true,
                    onAccept: () => _respond(item, 'accepted'),
                    onDecline: () => _respond(item, 'declined'),
                  )),
            const SizedBox(height: 20),
            const Text('Recent requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const AppCard(child: Text('No requests yet.', style: TextStyle(color: AppColors.textMuted)))
            else
              ...recent.map((item) => _RequestCard(request: item)),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    this.showActions = false,
    this.onAccept,
    this.onDecline,
  });

  final Map<String, dynamic> request;
  final bool showActions;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final couple = request['couple'] as Map<String, dynamic>?;
    final plan = request['wedding_plan'] as Map<String, dynamic>?;
    final status = request['status'] as String? ?? 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(couple?['name'] as String? ?? 'Couple request', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (plan?['title'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(plan!['title'] as String, style: const TextStyle(color: AppColors.textMuted)),
              ),
            if (request['message'] != null) ...[
              const SizedBox(height: 8),
              Text(request['message'] as String),
            ],
            const SizedBox(height: 8),
            Text('Status: $status', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepGreen)),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
