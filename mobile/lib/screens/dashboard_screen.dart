import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';
import 'package:wedplan_ghana/theme/app_theme.dart';
import 'package:wedplan_ghana/utils/parse_utils.dart';
import 'package:wedplan_ghana/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.weddingService, required this.onCreatePlan});

  final WeddingService weddingService;
  final VoidCallback onCreatePlan;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      final response = await widget.weddingService.dashboard();
      setState(() => _data = response['data'] as Map<String, dynamic>);
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasPlan = _data?['has_plan'] == true;
    if (!hasPlan) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 72, color: AppTheme.gold),
              const SizedBox(height: 16),
              const Text(
                'No wedding plan yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Create your first plan to start budgeting, scheduling, and managing guests.'),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: widget.onCreatePlan, child: const Text('Create Wedding Plan')),
            ],
          ),
        ),
      );
    }

    final plan = _data!['plan'] as Map<String, dynamic>;
    final stats = _data!['stats'] as Map<String, dynamic>;
    final tasks = (_data!['upcoming_tasks'] as List<dynamic>? ?? []);

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
                  Text(plan['title']?.toString() ?? 'Wedding Plan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${plan['bride_name'] ?? ''} & ${plan['groom_name'] ?? ''}'),
                  if (plan['wedding_date'] != null)
                    Text('Date: ${DateFormat.yMMMd().format(DateTime.parse(plan['wedding_date']))}'),
                  if (plan['location'] != null) Text('Venue: ${plan['location']}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ((plan['ceremony_types'] as List<dynamic>? ?? [])
                        .map((item) => Chip(label: Text(item.toString()), backgroundColor: AppTheme.gold.withValues(alpha: 0.2)))
                        .toList()),
                  ),
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
              StatCard(title: 'Guests', value: '${stats['guests_count']}', icon: Icons.people),
              StatCard(title: 'Confirmed', value: '${stats['confirmed_guests']}', icon: Icons.check_circle),
              StatCard(title: 'Tasks', value: '${stats['pending_tasks']}', icon: Icons.task_alt),
              StatCard(
                title: 'Budget Left',
                value: 'GHS ${NumberFormat('#,##0').format(parseAmount(stats['budget_remaining']))}',
                icon: Icons.account_balance_wallet,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Upcoming Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            const Card(child: ListTile(title: Text('No upcoming tasks yet.')))
          else
            ...tasks.map(
              (task) => Card(
                child: ListTile(
                  leading: const Icon(Icons.event_note, color: AppTheme.deepGreen),
                  title: Text(task['title'].toString()),
                  subtitle: Text(task['due_date'] != null ? 'Due ${task['due_date']}' : 'No due date'),
                  trailing: Text(task['status'].toString()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
