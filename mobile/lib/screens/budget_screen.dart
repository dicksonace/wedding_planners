import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';
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

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Budget Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: estimatedController,
              decoration: const InputDecoration(labelText: 'Estimated Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
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
    });
    await _load();
  }

  String _format(dynamic value) => NumberFormat('#,##0.00').format(parseAmount(value));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

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
            if (_summary != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Budget: GHS ${_format(parseAmount(_summary!['total_budget']))}'),
                      Text('Estimated: GHS ${_format(parseAmount(_summary!['estimated_total']))}'),
                      Text('Actual Spent: GHS ${_format(parseAmount(_summary!['actual_total']))}'),
                      Text('Paid: GHS ${_format(parseAmount(_summary!['paid_total']))}'),
                    ],
                  ),
                ),
              ),
            ..._items.map(
              (item) {
                final budget = item as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(budget['description'].toString()),
                    subtitle: Text('${budget['category']} • Est: GHS ${_format(parseAmount(budget['estimated_amount']))}'),
                    trailing: budget['is_paid'] == true ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
