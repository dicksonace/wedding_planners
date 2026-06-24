import 'package:flutter/material.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.weddingService, required this.planId});

  final WeddingService weddingService;
  final int planId;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _tasks = await widget.weddingService.tasks(widget.planId);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String ceremony = 'traditional';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            DropdownButtonFormField<String>(
              initialValue: ceremony,
              items: const [
                DropdownMenuItem(value: 'knocking', child: Text('Knocking')),
                DropdownMenuItem(value: 'engagement', child: Text('Engagement')),
                DropdownMenuItem(value: 'traditional', child: Text('Traditional')),
                DropdownMenuItem(value: 'church', child: Text('Church')),
                DropdownMenuItem(value: 'reception', child: Text('Reception')),
              ],
              onChanged: (value) => ceremony = value ?? ceremony,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || titleController.text.trim().isEmpty) return;

    await widget.weddingService.addTask(widget.planId, {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'ceremony_type': ceremony,
      'priority': 'medium',
      'status': 'pending',
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add_task),
        label: const Text('Add Task'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index] as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(task['title'].toString()),
                subtitle: Text('${task['ceremony_type'] ?? 'general'} • ${task['description'] ?? ''}'),
                trailing: Chip(label: Text(task['status'].toString())),
              ),
            );
          },
        ),
      ),
    );
  }
}
