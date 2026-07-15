import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_plan_screen.dart';
import 'home_shell.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = context.read<AppStore>();
    await store.refreshDashboard();
    if (store.hasPlan) await store.fetchBudgetItems();
  }

  Future<void> _openBudgetForm({Map<String, dynamic>? item}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BudgetItemSheet(item: item),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    if (!store.hasPlan) {
      return Scaffold(
        appBar: const CoupleAppBar(title: 'Budget'),
        floatingActionButton: AppAddFab(
          tooltip: 'Create plan',
          onPressed: () async {
            final created = await openCreatePlanScreen(context);
            if (created == true && mounted) await _load();
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: const NoPlanPlaceholder(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Budget tracking',
          subtitle: 'Create a wedding plan to start tracking expenses.',
        ),
      );
    }

    final summary = store.budgetSummary;
    final items = store.budgetItems;

    return Scaffold(
      appBar: const CoupleAppBar(title: 'Budget'),
      floatingActionButton: AppAddFab(
        tooltip: 'Add expense',
        onPressed: () => _openBudgetForm(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _load,
        child: store.budgetLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                    children: [
                      StatTile(
                        icon: Icons.payments,
                        label: 'Total budget',
                        value: formatMoney(asNum(summary?['total_budget'] ?? store.coupleDashboard?['stats']?['total_budget'])),
                      ),
                      StatTile(
                        icon: Icons.savings,
                        label: 'Remaining',
                        value: formatMoney(asNum(summary?['budget_remaining'] ?? store.coupleDashboard?['stats']?['budget_remaining'])),
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty) ...[
                    const EmptyState(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'No budget items yet',
                      subtitle: 'Add venue, catering, photography and other wedding expenses.',
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Add Expense',
                      icon: Icons.add,
                      onPressed: () => _openBudgetForm(),
                    ),
                  ] else
                    ...items.map((item) => _BudgetItemCard(
                          item: item,
                          onEdit: () => _openBudgetForm(item: item),
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete expense?'),
                                content: Text('Remove ${item['category']} from your budget?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await store.deleteBudgetItem(item['id'] as int);
                            }
                          },
                        )),
                ],
              ),
      ),
    );
  }
}

class _BudgetItemCard extends StatelessWidget {
  const _BudgetItemCard({required this.item, required this.onEdit, required this.onDelete});

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPaid = item['is_paid'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onEdit,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['category'] as String? ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (item['description'] != null)
                    Text(item['description'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    'Estimated: ${formatMoney(asNum(item['estimated_amount']))}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (asNum(item['actual_amount']) > 0)
                    Text(
                      'Paid: ${formatMoney(asNum(item['actual_amount']))}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatMoney(asNum(item['estimated_amount'])), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  isPaid ? 'Paid' : 'Unpaid',
                  style: TextStyle(
                    color: isPaid ? AppColors.deepGreen : AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.richRed, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetItemSheet extends StatefulWidget {
  const _BudgetItemSheet({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_BudgetItemSheet> createState() => _BudgetItemSheetState();
}

class _BudgetItemSheetState extends State<_BudgetItemSheet> {
  static const _categories = [
    'Venue',
    'Catering',
    'Photography',
    'Decoration',
    'Music',
    'Attire',
    'Transportation',
    'Gifts',
    'Other',
  ];

  late final TextEditingController _description;
  late final TextEditingController _estimated;
  late final TextEditingController _actual;
  late String _category;
  late bool _isPaid;
  bool _submitting = false;
  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _category = item?['category'] as String? ?? 'Venue';
    _description = TextEditingController(text: item?['description'] as String? ?? '');
    _estimated = TextEditingController(text: item?['estimated_amount']?.toString() ?? '');
    _actual = TextEditingController(text: item?['actual_amount']?.toString() ?? '');
    _isPaid = item?['is_paid'] == true;
  }

  @override
  void dispose() {
    _description.dispose();
    _estimated.dispose();
    _actual.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_description.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      final payload = {
        'category': _category,
        'description': _description.text.trim(),
        'estimated_amount': _estimated.text.trim().isEmpty ? null : double.tryParse(_estimated.text.trim()),
        'actual_amount': _actual.text.trim().isEmpty ? null : double.tryParse(_actual.text.trim()),
        'is_paid': _isPaid,
      };

      final store = context.read<AppStore>();
      if (_isEditing) {
        await store.updateBudgetItem(widget.item!['id'] as int, payload);
      } else {
        await store.addBudgetItem(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Edit Expense' : 'Add Expense',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _categories.contains(_category) ? _category : 'Other',
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Other'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description *')),
          const SizedBox(height: 12),
          TextField(
            controller: _estimated,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Estimated amount (GHS)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actual,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount paid (GHS)'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark as paid'),
            value: _isPaid,
            onChanged: (v) => setState(() => _isPaid = v),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: _isEditing ? 'Save Changes' : 'Add Expense',
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
