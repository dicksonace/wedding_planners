import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'guests_screen.dart';
import 'vendors_screen.dart';

class CoupleHomeShell extends StatefulWidget {
  const CoupleHomeShell({super.key});

  @override
  State<CoupleHomeShell> createState() => _CoupleHomeShellState();
}

class _CoupleHomeShellState extends State<CoupleHomeShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.dashboard_rounded, label: 'Home'),
    (icon: Icons.people_alt_rounded, label: 'Guests'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Budget'),
    (icon: Icons.checklist_rounded, label: 'Tasks'),
    (icon: Icons.storefront_rounded, label: 'Vendors'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),
      GuestsScreen(),
      BudgetScreen(),
      TasksScreen(),
      VendorsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

class PlanRequiredBanner extends StatelessWidget {
  const PlanRequiredBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.event, color: AppColors.gold, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Create a wedding plan first', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Set up your ceremony details to unlock this section.', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatMoney(num value) => NumberFormat.currency(symbol: 'GHS ', decimalDigits: 0).format(value);
