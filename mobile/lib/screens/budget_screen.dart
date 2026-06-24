import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';
import 'package:wedplan_ghana/theme/app_theme.dart';
import 'package:wedplan_ghana/utils/parse_utils.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.weddingService, required this.planId});

  final WeddingService weddingService;
  final int planId;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<dynamic> _items = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await widget.weddingService.budgetItems(widget.planId);
      _items = response['data'] as List<dynamic>;
      _summary = response['summary'] as Map<String, dynamic>;
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addItem() async {
    final categoryController = TextEditingController(text: 'Venue');
    final descriptionController = TextEditingController();
    final estimatedController = TextEditingController();
    final actualController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Budget Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                controller: estimatedController,
                decoration: const InputDecoration(labelText: 'Planned amount (GHS)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: actualController,
                decoration: const InputDecoration(labelText: 'Actual amount (GHS)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || descriptionController.text.trim().isEmpty) return;

    await widget.weddingService.addBudgetItem(widget.planId, {
      'category': categoryController.text.trim(),
      'description': descriptionController.text.trim(),
      'estimated_amount': double.tryParse(estimatedController.text) ?? 0,
      'actual_amount': double.tryParse(actualController.text) ?? 0,
    });
    await _load();
  }

  Future<void> _togglePaid(Map<String, dynamic> item) async {
    final isPaid = item['is_paid'] != true;
    await widget.weddingService.updateBudgetItem(widget.planId, item['id'] as int, {
      'is_paid': isPaid,
      if (isPaid) 'actual_amount': parseAmount(item['actual_amount']) > 0 ? parseAmount(item['actual_amount']) : parseAmount(item['estimated_amount']),
    });
    await _load();
  }

  String _format(dynamic value) => NumberFormat('#,##0.00').format(parseAmount(value));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final spentPercent = parseAmount(_summary?['spent_percent']);
    final overBudget = parseAmount(_summary?['over_budget']) > 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_summary != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wedding budget overview', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Text('Total plan budget: GHS ${_format(_summary!['total_budget'])}'),
                      Text('Planned (estimated): GHS ${_format(_summary!['estimated_total'])}'),
                      Text('Actually spent: GHS ${_format(_summary!['actual_total'])}'),
                      Text('Paid so far: GHS ${_format(_summary!['paid_total'])}'),
                      Text('Still unpaid: GHS ${_format(_summary!['unpaid_total'])}'),
                      Text('Remaining: GHS ${_format(_summary!['budget_remaining'])}'),
                      if (overBudget)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Over budget by GHS ${_format(_summary!['over_budget'])}',
                            style: const TextStyle(color: AppTheme.richRed, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (spentPercent / 100).clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: overBudget ? AppTheme.richRed : AppTheme.deepGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${spentPercent.toStringAsFixed(1)}% of total budget used'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Set your total budget in the wedding plan. Add line items here to track venue, catering, photography, etc.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            ..._items.map((item) {
              final budget = item as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(budget['description'].toString()),
                  subtitle: Text(
                    '${budget['category']} • Planned: GHS ${_format(budget['estimated_amount'])} • Actual: GHS ${_format(budget['actual_amount'])}',
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      budget['is_paid'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: budget['is_paid'] == true ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _togglePaid(budget),
                    tooltip: 'Mark paid',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
