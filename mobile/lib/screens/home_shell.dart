import 'package:flutter/material.dart';
import 'package:wedplan_ghana/models/user.dart';
import 'package:wedplan_ghana/screens/budget_screen.dart';
import 'package:wedplan_ghana/screens/create_plan_screen.dart';
import 'package:wedplan_ghana/screens/dashboard_screen.dart';
import 'package:wedplan_ghana/screens/guests_screen.dart';
import 'package:wedplan_ghana/screens/tasks_screen.dart';
import 'package:wedplan_ghana/screens/vendors_screen.dart';
import 'package:wedplan_ghana/services/auth_service.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.user,
    required this.authService,
    required this.weddingService,
    required this.onLogout,
  });

  final User user;
  final AuthService authService;
  final WeddingService weddingService;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int? _planId;
  Key _dashboardKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadPlanId();
  }

  Future<void> _loadPlanId() async {
    try {
      final plans = await widget.weddingService.weddingPlans();
      if (plans.isNotEmpty) {
        setState(() => _planId = plans.first['id'] as int);
      }
    } catch (_) {}
  }

  Future<void> _openCreatePlan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(
          weddingService: widget.weddingService,
          onCreated: () {
            _loadPlanId();
            setState(() => _dashboardKey = UniqueKey());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Guests', 'Budget', 'Tasks', 'Vendors'];

    return Scaffold(
      appBar: AppBar(
        title: Text('WedPlan • ${titles[_index]}'),
        actions: [
          IconButton(
            tooltip: 'Create plan',
            onPressed: _openCreatePlan,
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            key: _dashboardKey,
            weddingService: widget.weddingService,
            onCreatePlan: _openCreatePlan,
          ),
          _planId == null
              ? _emptyState('Create a wedding plan to manage guests.')
              : GuestsScreen(weddingService: widget.weddingService, planId: _planId!),
          _planId == null
              ? _emptyState('Create a wedding plan to track your budget.')
              : BudgetScreen(weddingService: widget.weddingService, planId: _planId!),
          _planId == null
              ? _emptyState('Create a wedding plan to manage tasks.')
              : TasksScreen(weddingService: widget.weddingService, planId: _planId!),
          VendorsScreen(weddingService: widget.weddingService, planId: _planId),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Guests'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Budget'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Vendors'),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _openCreatePlan, child: const Text('Create Wedding Plan')),
          ],
        ),
      ),
    );
  }
}
