import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'budget_screen.dart';
import 'create_plan_screen.dart';
import 'dashboard_screen.dart';
import 'guests_screen.dart';
import 'tasks_screen.dart';
import 'vendors_screen.dart';

class CoupleHomeShell extends StatefulWidget {
  const CoupleHomeShell({super.key});

  @override
  State<CoupleHomeShell> createState() => _CoupleHomeShellState();
}

class _CoupleHomeShellState extends State<CoupleHomeShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.home_rounded, activeIcon: Icons.home_filled, label: 'Home'),
    (icon: Icons.people_alt_outlined, activeIcon: Icons.people_alt_rounded, label: 'Guests'),
    (icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Budget'),
    (icon: Icons.checklist_rtl_outlined, activeIcon: Icons.checklist_rounded, label: 'Tasks'),
    (icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Vendors'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNavigate: (i) => setState(() => _index = i)),
      const GuestsScreen(),
      const BudgetScreen(),
      const TasksScreen(),
      const VendorsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _index,
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.softGreen,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final tab in _tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.activeIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanRequiredBanner extends StatelessWidget {
  const PlanRequiredBanner({super.key, this.onCreatePlan});

  final VoidCallback? onCreatePlan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.event_rounded, color: AppColors.goldDark, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Create a wedding plan first', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      'Set up your ceremony details, then you can add guests, budget, and tasks.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onCreatePlan != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(label: 'Create Wedding Plan', icon: Icons.add_rounded, onPressed: onCreatePlan),
          ],
        ],
      ),
    );
  }
}

String formatMoney(num value) => NumberFormat.currency(symbol: 'GHS ', decimalDigits: 0).format(value);

num asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

Future<void> _openCreatePlan(BuildContext context) async {
  final created = await openCreatePlanScreen(context);
  if (created == true && context.mounted) {
    await context.read<AppStore>().refreshDashboard();
  }
}

class NoPlanPlaceholder extends StatelessWidget {
  const NoPlanPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PlanRequiredBanner(onCreatePlan: () => _openCreatePlan(context)),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Create Wedding Plan',
          icon: Icons.add_rounded,
          onPressed: () => _openCreatePlan(context),
        ),
        const SizedBox(height: 32),
        EmptyState(icon: icon, title: title, subtitle: subtitle),
      ],
    );
  }
}
