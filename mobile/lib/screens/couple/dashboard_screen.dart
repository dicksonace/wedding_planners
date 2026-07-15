import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_plan_screen.dart';
import 'home_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigate});

  final void Function(int tabIndex)? onNavigate;

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
    final totalBudget = asNum(stats?['total_budget']);
    final spent = asNum(stats?['actual_spent']);
    final progress = totalBudget > 0 ? (spent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: AppAddFab(
        tooltip: hasPlan ? 'Quick add' : 'Create plan',
        onPressed: () async {
          if (!hasPlan) {
            final created = await openCreatePlanScreen(context);
            if (created == true && mounted) {
              await store.refreshDashboard();
              setState(() {});
            }
          } else {
            _showQuickAdd(context);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: store.refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Hello, ${user.name.split(' ').first}',
                subtitle: hasPlan ? (plan?['title'] as String? ?? 'Your wedding plan') : "Let's plan your perfect Ghana wedding",
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!hasPlan)
                    Column(
                      children: [
                        const EmptyState(
                          icon: Icons.celebration_rounded,
                          title: 'Start your journey',
                          subtitle: 'Create your wedding plan with knocking, engagement, traditional, church and reception details.',
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Create Wedding Plan',
                          icon: Icons.add_rounded,
                          onPressed: () async {
                            final created = await openCreatePlanScreen(context);
                            if (created == true && mounted) {
                              await store.refreshDashboard();
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    )
                  else ...[
                    if (hasPlan) ...[
                      const SectionTitle(title: 'Quick actions'),
                      SizedBox(
                        height: 96,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            QuickActionChip(icon: Icons.people_alt_rounded, label: 'Guests', onTap: () => widget.onNavigate?.call(1)),
                            const SizedBox(width: 12),
                            QuickActionChip(icon: Icons.account_balance_wallet_rounded, label: 'Budget', onTap: () => widget.onNavigate?.call(2)),
                            const SizedBox(width: 12),
                            QuickActionChip(icon: Icons.checklist_rounded, label: 'Tasks', onTap: () => widget.onNavigate?.call(3)),
                            const SizedBox(width: 12),
                            QuickActionChip(icon: Icons.storefront_rounded, label: 'Vendors', onTap: () => widget.onNavigate?.call(4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SectionTitle(title: 'Your stats'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                      children: [
                        StatTile(icon: Icons.people_alt_rounded, label: 'Guests', value: '${stats?['guests_count'] ?? 0}'),
                        StatTile(icon: Icons.verified_rounded, label: 'Confirmed', value: '${stats?['confirmed_guests'] ?? 0}', color: AppColors.goldDark),
                        StatTile(icon: Icons.task_alt_rounded, label: 'Pending tasks', value: '${stats?['pending_tasks'] ?? 0}', color: AppColors.deepGreenLight),
                        StatTile(icon: Icons.savings_rounded, label: 'Budget left', value: formatMoney(asNum(stats?['budget_remaining'])), color: AppColors.gold),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Budget progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Spent ${formatMoney(spent)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('of ${formatMoney(totalBudget)}', style: const TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: AppColors.softGreen,
                              color: AppColors.deepGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${(progress * 100).round()}% of budget used', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Wedding overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          _overviewRow(Icons.calendar_month_rounded, 'Ceremony date', _formatDate(plan?['wedding_date'])),
                          _overviewRow(Icons.location_on_rounded, 'Region', plan?['region']?.toString() ?? '-'),
                          _overviewRow(Icons.payments_rounded, 'Total budget', formatMoney(totalBudget)),
                          _overviewRow(Icons.receipt_long_rounded, 'Actual spent', formatMoney(spent)),
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

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: AppDecor.radiusLg),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Quick add', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add_rounded, color: AppColors.deepGreen),
              title: const Text('Add guest'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onNavigate?.call(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_rounded, color: AppColors.deepGreen),
              title: const Text('Add expense'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onNavigate?.call(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_rounded, color: AppColors.deepGreen),
              title: const Text('Add task'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onNavigate?.call(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_rounded, color: AppColors.deepGreen),
              title: const Text('Find vendors'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onNavigate?.call(4);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final raw = value.toString();
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Widget _overviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppColors.deepGreen),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
