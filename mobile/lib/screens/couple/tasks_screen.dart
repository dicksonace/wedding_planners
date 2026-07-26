import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    if (store.hasPlan) {
      await Future.wait([store.fetchTasks(), store.fetchReminders()]);
    }
  }

  Future<void> _openTaskForm({Map<String, dynamic>? task}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskSheet(task: task),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _openReminderForm({Map<String, dynamic>? reminder}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReminderSheet(reminder: reminder),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _toggleComplete(Map<String, dynamic> task) async {
    final current = task['status'] as String? ?? 'pending';
    final next = current == 'completed' ? 'pending' : 'completed';
    await context.read<AppStore>().updateTask(task['id'] as int, {'status': next});
    if (mounted) await _load();
  }

  Future<void> _toggleReminderDone(Map<String, dynamic> reminder) async {
    final done = reminder['is_done'] == true;
    await context.read<AppStore>().updateReminder(reminder['id'] as int, {'is_done': !done});
    if (mounted) await _load();
  }

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: AppDecor.radiusLg),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: AppColors.deepGreen),
              title: const Text('Add planning task'),
              onTap: () {
                Navigator.pop(ctx);
                _openTaskForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm_rounded, color: AppColors.goldDark),
              title: const Text('Add reminder / appointment'),
              subtitle: const Text('Dress fitting, hair, makeup, etc.'),
              onTap: () {
                Navigator.pop(ctx);
                _openReminderForm();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    if (!store.hasPlan) {
      return Scaffold(
        appBar: const CoupleAppBar(title: 'Tasks & Reminders'),
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
          subtitle: 'Create a wedding plan to manage your checklist and reminders.',
        ),
      );
    }

    final tasks = store.tasks;
    final reminders = store.reminders;
    final loading = store.tasksLoading || store.remindersLoading;

    return Scaffold(
      appBar: const CoupleAppBar(title: 'Tasks & Reminders'),
      floatingActionButton: AppAddFab(
        tooltip: 'Add task or reminder',
        onPressed: _showAddMenu,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  Row(
                    children: [
                      const Expanded(child: SectionTitle(title: 'Reminders')),
                      TextButton.icon(
                        onPressed: () => _openReminderForm(),
                        icon: const Icon(Icons.add_alarm_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (reminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Track dress fittings, hairstylist, makeup, and other appointments with date & time.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  else
                    ...reminders.map((reminder) {
                      final done = reminder['is_done'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => _openReminderForm(reminder: reminder),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(
                                  done ? Icons.check_circle : Icons.alarm_rounded,
                                  color: done ? AppColors.deepGreen : AppColors.goldDark,
                                ),
                                onPressed: () => _toggleReminderDone(reminder),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reminder['title'] as String? ?? 'Reminder',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        decoration: done ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDateTime(reminder['remind_at']),
                                      style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    if (reminder['category'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: _chip(_categoryLabel(reminder['category']?.toString()), AppColors.gold),
                                      ),
                                    if (reminder['notes'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(reminder['notes'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                                      title: const Text('Delete reminder?'),
                                      content: Text('Remove "${reminder['title']}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await store.deleteReminder(reminder['id'] as int);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: SectionTitle(title: 'Planning tasks')),
                      TextButton.icon(
                        onPressed: () => _openTaskForm(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (tasks.isEmpty)
                    const EmptyState(
                      icon: Icons.checklist_rounded,
                      title: 'No tasks yet',
                      subtitle: 'Add knocking, engagement, traditional and reception checklist items.',
                    )
                  else
                    ...tasks.map((task) {
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
                    }),
                ],
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

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return DateFormat('EEE, MMM d · h:mm a').format(parsed.toLocal());
  }

  String _categoryLabel(String? key) {
    switch (key) {
      case 'fitting':
        return 'Dress fitting';
      case 'hair':
        return 'Hairstylist';
      case 'makeup':
        return 'Makeup';
      case 'venue':
        return 'Venue';
      case 'vendor':
        return 'Vendor';
      default:
        return 'Other';
    }
  }
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({this.reminder});

  final Map<String, dynamic>? reminder;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  static const _categories = [
    ('fitting', 'Dress fitting'),
    ('hair', 'Hairstylist'),
    ('makeup', 'Makeup'),
    ('venue', 'Venue'),
    ('vendor', 'Vendor'),
    ('other', 'Other'),
  ];

  late final TextEditingController _title;
  late final TextEditingController _notes;
  late String _category;
  DateTime _remindAt = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;
  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _title = TextEditingController(text: reminder?['title'] as String? ?? '');
    _notes = TextEditingController(text: reminder?['notes'] as String? ?? '');
    _category = reminder?['category'] as String? ?? 'other';
    final parsed = DateTime.tryParse(reminder?['remind_at']?.toString() ?? '');
    if (parsed != null) _remindAt = parsed.toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _remindAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_remindAt),
    );
    if (time == null) return;

    setState(() {
      _remindAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      final payload = {
        'title': _title.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'category': _category,
        'remind_at': _remindAt.toIso8601String(),
      };

      final store = context.read<AppStore>();
      if (_isEditing) {
        await store.updateReminder(widget.reminder!['id'] as int, payload);
      } else {
        await store.addReminder(payload);
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
          Text(_isEditing ? 'Edit Reminder' : 'Add Reminder', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Dress fitting')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categories.any((c) => c.$1 == _category) ? _category : 'other',
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'other'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_rounded, color: AppColors.deepGreen),
            title: const Text('Date & time'),
            subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(_remindAt)),
            trailing: const Icon(Icons.edit_calendar_rounded),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 12),
          TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 8),
          PrimaryButton(label: _isEditing ? 'Save Changes' : 'Save Reminder', loading: _submitting, onPressed: _submit),
        ],
      ),
    );
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
