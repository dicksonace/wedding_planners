import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_plan_screen.dart';
import 'home_shell.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = context.read<AppStore>();
    await store.refreshDashboard();
    if (store.hasPlan) await store.fetchTasks();
  }

  Future<void> _openTaskForm({Map<String, dynamic>? task}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskSheet(task: task),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _toggleComplete(Map<String, dynamic> task) async {
    final current = task['status'] as String? ?? 'pending';
    final next = current == 'completed' ? 'pending' : 'completed';
    await context.read<AppStore>().updateTask(task['id'] as int, {'status': next});
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    if (!store.hasPlan) {
      return Scaffold(
        appBar: const CoupleAppBar(title: 'Tasks'),
        floatingActionButton: AppAddFab(
          tooltip: 'Create plan',
          onPressed: () async {
            final created = await openCreatePlanScreen(context);
            if (created == true && mounted) await _load();
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: const NoPlanPlaceholder(
          icon: Icons.checklist_rounded,
          title: 'Planning tasks',
          subtitle: 'Create a wedding plan to manage your checklist.',
        ),
      );
    }

    final tasks = store.tasks;

    return Scaffold(
      appBar: const CoupleAppBar(title: 'Tasks'),
      floatingActionButton: AppAddFab(
        tooltip: 'Add task',
        onPressed: () => _openTaskForm(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _load,
        child: store.tasksLoading
            ? const Center(child: CircularProgressIndicator())
            : tasks.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 40),
                      const EmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'No tasks yet',
                        subtitle: 'Add knocking, engagement, traditional and reception checklist items.',
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(label: 'Add Task', icon: Icons.add, onPressed: () => _openTaskForm()),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      final status = task['status'] as String? ?? 'pending';
                      final isDone = status == 'completed';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => _openTaskForm(task: task),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isDone ? AppColors.deepGreen : AppColors.textMuted,
                                ),
                                onPressed: () => _toggleComplete(task),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['title'] as String? ?? 'Task',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (task['description'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(task['description'] as String, style: const TextStyle(color: AppColors.textMuted)),
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _chip('Status: $status', AppColors.deepGreen),
                                        if (task['priority'] != null) _chip('${task['priority']}', AppColors.gold),
                                        if (task['ceremony_type'] != null) _chip('${task['ceremony_type']}', AppColors.textMuted),
                                        if (task['due_date'] != null) _chip('Due: ${_formatDate(task['due_date'])}', AppColors.textMuted),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.richRed),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete task?'),
                                      content: Text('Remove "${task['title']}" from your checklist?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await store.deleteTask(task['id'] as int);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(dynamic value) {
    final raw = value.toString();
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
}

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({this.task});

  final Map<String, dynamic>? task;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  static const _statuses = ['pending', 'in_progress', 'completed'];
  static const _priorities = ['low', 'medium', 'high'];
  static const _ceremonies = ['knocking', 'engagement', 'traditional', 'church', 'reception'];

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _dueDate;
  late String _status;
  late String _priority;
  String? _ceremony;
  bool _submitting = false;
  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?['title'] as String? ?? '');
    _description = TextEditingController(text: task?['description'] as String? ?? '');
    _dueDate = TextEditingController(text: _formatDate(task?['due_date']));
    _status = task?['status'] as String? ?? 'pending';
    _priority = task?['priority'] as String? ?? 'medium';
    _ceremony = task?['ceremony_type'] as String?;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _dueDate.dispose();
    super.dispose();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      _dueDate.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      final payload = {
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'due_date': _dueDate.text.trim().isEmpty ? null : _dueDate.text.trim(),
        'status': _status,
        'priority': _priority,
        'ceremony_type': _ceremony,
      };

      final store = context.read<AppStore>();
      if (_isEditing) {
        await store.updateTask(widget.task!['id'] as int, payload);
      } else {
        await store.addTask(payload);
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
          Text(_isEditing ? 'Edit Task' : 'Add Task', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title *')),
          const SizedBox(height: 12),
          TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          TextField(
            controller: _dueDate,
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(labelText: 'Due date', suffixIcon: Icon(Icons.calendar_today)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _statuses.contains(_status) ? _status : 'pending',
            decoration: const InputDecoration(labelText: 'Status'),
            items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _status = v ?? 'pending'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _priorities.contains(_priority) ? _priority : 'medium',
            decoration: const InputDecoration(labelText: 'Priority'),
            items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _priority = v ?? 'medium'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _ceremony,
            decoration: const InputDecoration(labelText: 'Ceremony type'),
            items: [
              const DropdownMenuItem(value: null, child: Text('General')),
              ..._ceremonies.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) => setState(() => _ceremony = v),
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: _isEditing ? 'Save Changes' : 'Add Task', loading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}
