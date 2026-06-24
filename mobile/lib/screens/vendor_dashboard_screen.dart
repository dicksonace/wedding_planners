import 'package:flutter/material.dart';
import 'package:wedplan_ghana/services/vendor_service.dart';
import 'package:wedplan_ghana/theme/app_theme.dart';
import 'package:wedplan_ghana/widgets/stat_card.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({
    super.key,
    required this.vendorService,
    required this.onUpdated,
  });

  final VendorService vendorService;
  final VoidCallback onUpdated;

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await widget.vendorService.dashboard();
      setState(() => _data = response['data'] as Map<String, dynamic>);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(Map<String, dynamic> request, String status) async {
    try {
      await widget.vendorService.respondToRequest(request['id'] as int, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${status}')),
        );
      }
      await _load();
      widget.onUpdated();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final vendor = _data?['vendor'] as Map<String, dynamic>?;
    final stats = _data?['stats'] as Map<String, dynamic>? ?? {};
    final pending = (_data?['pending_requests'] as List<dynamic>? ?? []);
    final recent = (_data?['recent_requests'] as List<dynamic>? ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor?['business_name']?.toString() ?? 'Vendor Profile',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Category: ${vendor?['category'] ?? ''}'),
                  Text('Location: ${vendor?['location'] ?? 'Ghana'}'),
                  if (vendor?['description'] != null) Text(vendor!['description'].toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              StatCard(title: 'Total Requests', value: '${stats['total_requests'] ?? 0}', icon: Icons.inbox),
              StatCard(title: 'Pending', value: '${stats['pending_requests'] ?? 0}', icon: Icons.pending_actions),
              StatCard(title: 'Accepted', value: '${stats['accepted_requests'] ?? 0}', icon: Icons.check_circle),
              StatCard(title: 'Declined', value: '${stats['declined_requests'] ?? 0}', icon: Icons.cancel),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Pending couple requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Card(child: ListTile(title: Text('No pending requests right now.')))
          else
            ...pending.map((item) {
              final request = item as Map<String, dynamic>;
              final plan = request['wedding_plan'] as Map<String, dynamic>?;
              final couple = request['couple'] as Map<String, dynamic>?;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan?['title']?.toString() ?? 'Wedding plan', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('From: ${couple?['name'] ?? 'Couple'}'),
                      if (request['message'] != null) Text(request['message'].toString()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _respond(request, 'accepted'),
                            child: const Text('Accept'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _respond(request, 'declined'),
                            child: const Text('Decline'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
          const Text('Recent activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...recent.map((item) {
            final request = item as Map<String, dynamic>;
            return ListTile(
              leading: Icon(Icons.storefront, color: AppTheme.deepGreen),
              title: Text(request['wedding_plan']?['title']?.toString() ?? 'Request'),
              subtitle: Text('Status: ${request['status']}'),
            );
          }),
        ],
      ),
    );
  }
}
