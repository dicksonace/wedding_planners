import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../widgets/common_widgets.dart';
import 'home_shell.dart';

class GuestsScreen extends StatelessWidget {
  const GuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasPlan = context.watch<AppStore>().coupleDashboard?['has_plan'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Guest List')),
      body: hasPlan
          ? const EmptyState(
              icon: Icons.people_alt_rounded,
              title: 'Guest management ready',
              subtitle: 'Track RSVPs, send invites, and manage your guest list here.',
            )
          : const Padding(padding: EdgeInsets.all(20), child: PlanRequiredBanner()),
    );
  }
}

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasPlan = context.watch<AppStore>().coupleDashboard?['has_plan'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: hasPlan
          ? const EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Budget tracker ready',
              subtitle: 'Monitor estimated vs actual costs for every ceremony item.',
            )
          : const Padding(padding: EdgeInsets.all(20), child: PlanRequiredBanner()),
    );
  }
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasPlan = context.watch<AppStore>().coupleDashboard?['has_plan'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: hasPlan
          ? const EmptyState(
              icon: Icons.checklist_rounded,
              title: 'Task planner ready',
              subtitle: 'Organize knocking, engagement, traditional, and reception tasks.',
            )
          : const Padding(padding: EdgeInsets.all(20), child: PlanRequiredBanner()),
    );
  }
}
