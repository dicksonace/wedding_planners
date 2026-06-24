import 'package:flutter/material.dart';
import 'package:wedplan_ghana/models/user.dart';
import 'package:wedplan_ghana/screens/vendor_dashboard_screen.dart';
import 'package:wedplan_ghana/services/vendor_service.dart';

class VendorHomeShell extends StatefulWidget {
  const VendorHomeShell({
    super.key,
    required this.user,
    required this.vendorService,
    required this.onLogout,
  });

  final User user;
  final VendorService vendorService;
  final VoidCallback onLogout;

  @override
  State<VendorHomeShell> createState() => _VendorHomeShellState();
}

class _VendorHomeShellState extends State<VendorHomeShell> {
  Key _dashboardKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WedPlan Vendor Portal'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: VendorDashboardScreen(
        key: _dashboardKey,
        vendorService: widget.vendorService,
        onUpdated: () => setState(() => _dashboardKey = UniqueKey()),
      ),
    );
  }
}
