import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';
import '../add_task/add_task_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategoryId;
  Priority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.filter),
                        onPressed: () => _showFilterSheet(context),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.search_normal),
                        onPressed: () {
                          // TODO: Implement search
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter chips
            if (_selectedCategoryId != null || _selectedPriority != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (_selectedCategoryId != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            categories
                                .firstWhere((c) => c.id == _selectedCategoryId,
                                    orElse: () => categories.first)
                                .name,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () =>
                              setState(() => _selectedCategoryId = null),
                        ),
                      ),
                    if (_selectedPriority != null)
                      Chip(
                        label: Text(_priorityLabel(_selectedPriority!)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _selectedPriority = null),
                      ),
                  ],
                ),
              ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w400, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Progress'),
                  Tab(text: 'Done'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Task List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(_filterTasks(tasks)),
                  _buildTaskList(_filterTasks(tasks
                      .where((t) => t.status == TaskStatus.pending)
                      .toList())),
                  _buildTaskList(_filterTasks(tasks
                      .where((t) => t.status == TaskStatus.inProgress)
                      .toList())),
                  _buildTaskList(_filterTasks(tasks
                      .where((t) => t.status == TaskStatus.completed)
                      .toList())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    var filtered = tasks;

    if (_selectedCategoryId != null) {
      filtered =
          filtered.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    if (_selectedPriority != null) {
      filtered =
          filtered.where((t) => t.priority == _selectedPriority).toList();
    }

    // Sort by due date, then priority
    filtered.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return b.priority.index.compareTo(a.priority.index);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return filtered;
  }

  Widget _buildTaskList(List<Task> tasks) {
    final theme = Theme.of(context);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.task,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTaskScreen(editTask: task),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  icon: Iconsax.edit,
                  label: 'Edit',
                  borderRadius: BorderRadius.circular(12),
                ),
                SlidableAction(
                  onPressed: (_) {
                    ref.read(tasksProvider.notifier).deleteTask(task.id);
                  },
                  backgroundColor: AppTheme.priorityUrgent,
                  foregroundColor: Colors.white,
                  icon: Iconsax.trash,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            child: TaskCard(
              task: task,
              showCategory: true,
              onToggle: () =>
                  ref.read(tasksProvider.notifier).toggleTaskStatus(task.id),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskScreen(editTask: task),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05);
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    final categories = ref.read(categoriesProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _selectedPriority = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Category',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map((cat) => ChoiceChip(
                          label: Text(cat.name),
                          selected: _selectedCategoryId == cat.id,
                          onSelected: (selected) {
                            setState(() =>
                                _selectedCategoryId = selected ? cat.id : null);
                            setSheetState(() {});
                          },
                          selectedColor:
                              Color(cat.color).withValues(alpha: 0.3),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Priority',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: Priority.values
                    .map((p) => ChoiceChip(
                          label: Text(_priorityLabel(p)),
                          selected: _selectedPriority == p,
                          onSelected: (selected) {
                            setState(
                                () => _selectedPriority = selected ? p : null);
                            setSheetState(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }
}
