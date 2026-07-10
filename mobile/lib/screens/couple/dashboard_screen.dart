import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'home_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final user = store.user!;
    final data = store.coupleDashboard;
    final hasPlan = data?['has_plan'] == true;
    final stats = data?['stats'] as Map<String, dynamic>?;
    final plan = data?['plan'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        onRefresh: store.refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Hello, ${user.name.split(' ').first}',
                subtitle: hasPlan ? (plan?['title'] as String? ?? 'Your wedding plan') : "Let's start planning your big day",
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!hasPlan)
                    const EmptyState(
                      icon: Icons.celebration,
                      title: 'No wedding plan yet',
                      subtitle: 'Create your first plan with ceremony types like knocking, engagement, traditional, and reception.',
                    )
                  else ...[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        StatTile(icon: Icons.people, label: 'Guests', value: '${stats?['guests_count'] ?? 0}'),
                        StatTile(icon: Icons.check_circle, label: 'Confirmed', value: '${stats?['confirmed_guests'] ?? 0}', color: AppColors.gold),
                        StatTile(icon: Icons.task_alt, label: 'Pending tasks', value: '${stats?['pending_tasks'] ?? 0}'),
                        StatTile(icon: Icons.payments, label: 'Budget left', value: formatMoney((stats?['budget_remaining'] as num?) ?? 0)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Wedding overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          _row('Ceremony date', plan?['wedding_date']?.toString() ?? '-'),
                          _row('Region', plan?['region']?.toString() ?? '-'),
                          _row('Total budget', formatMoney((stats?['total_budget'] as num?) ?? 0)),
                          _row('Actual spent', formatMoney((stats?['actual_spent'] as num?) ?? 0)),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
