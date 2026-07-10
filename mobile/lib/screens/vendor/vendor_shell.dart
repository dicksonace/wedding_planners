import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final data = store.vendorDashboard;
    final stats = data?['stats'] as Map<String, dynamic>?;
    final pending = (data?['pending_requests'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await store.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
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
              childAspectRatio: 1.15,
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
              for (final item in pending)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['message']?.toString() ?? 'New request', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Status: ${item['status']}', style: const TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
