import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../data/models/timetable.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../providers/providers.dart';

// Provider for fetching sessions
final weeklySessionsProvider = FutureProvider.autoDispose((ref) async {
  // We can just return the repository here, logic is simple enough for now
  return ref.read(timetableRepositoryProvider);
});

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    // Default to current day (0-indexed for TabController, so weekday - 1)
    int initialIndex = DateTime.now().weekday - 1;
    _tabController =
        TabController(length: 7, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(timetableRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'College Timetable',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.disabledColor,
          indicatorColor: theme.colorScheme.primary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddClassDialog(context, repo),
            icon: const Icon(Iconsax.add_square),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (index) {
          final dayOfWeek = index + 1;
          final sessions = repo.getSortedSessionsForDay(dayOfWeek);
          return _buildDayView(context, sessions, repo);
        }),
      ),
    );
  }

  Widget _buildDayView(
      BuildContext context, List<ClassSession> sessions, var repo) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.calendar_remove, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildClassCard(context, session, repo);
      },
    );
  }

  Widget _buildClassCard(BuildContext context, ClassSession session, var repo) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      onDismissed: (_) {
        repo.deleteSession(session.id);
        setState(() {}); // Refresh UI
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: session.color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: session.color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: session.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.startTime.format(context),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: session.color,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            session.subjectName,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.roomNumber != null)
                Row(
                  children: [
                    Icon(Iconsax.location,
                        size: 14, color: theme.disabledColor),
                    const SizedBox(width: 4),
                    Text(session.roomNumber!,
                        style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              if (session.professorName != null)
                Row(
                  children: [
                    Icon(Iconsax.teacher, size: 14, color: theme.disabledColor),
                    const SizedBox(width: 4),
                    Text(session.professorName!,
                        style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(),
    );
  }

  void _showAddClassDialog(BuildContext context, var repo) {
    // Basic dialog implementation for MVP
    // Ideally this would be a separate widget/file
    showDialog(
      context: context,
      builder: (context) =>
          _AddClassDialog(repo: repo, initialDay: _tabController.index + 1),
    ).then((_) => setState(() {}));
  }
}

class _AddClassDialog extends StatefulWidget {
  final dynamic repo;
  final int initialDay;

  const _AddClassDialog({required this.repo, required this.initialDay});

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _professorController = TextEditingController();

  late Set<int> _selectedDays;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Color _selectedColor = Colors.blue;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selectedDays = {widget.initialDay};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Class'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g. Mathematics',
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Room (Optional)'),
              ),
              TextFormField(
                controller: _professorController,
                decoration:
                    const InputDecoration(labelText: 'Professor (Optional)'),
              ),
              const SizedBox(height: 16),
              const Text('Select Days',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: List.generate(7, (index) {
                  final dayNum = index + 1;
                  final isSelected = _selectedDays.contains(dayNum);
                  return FilterChip(
                    label: Text(_days[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(dayNum);
                        } else {
                          if (_selectedDays.length > 1) {
                            _selectedDays.remove(dayNum);
                          }
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Iconsax.clock, size: 18),
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: _startTime);
                        if (t != null) setState(() => _startTime = t);
                      },
                      label: Text('Start: ${_startTime.format(context)}'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Iconsax.clock, size: 18),
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: _endTime);
                        if (t != null) setState(() => _endTime = t);
                      },
                      label: Text('End: ${_endTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Label Color',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                ].map((c) {
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selectedColor == c
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: _selectedColor == c
                            ? [
                                BoxShadow(
                                    color: c.withOpacity(0.4), blurRadius: 4)
                              ]
                            : null,
                      ),
                      child: _selectedColor == c
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedDays.isNotEmpty) {
              final baseId = DateTime.now().millisecondsSinceEpoch;
              for (var day in _selectedDays) {
                final newClass = ClassSession(
                  id: '${baseId}_$day',
                  subjectName: _subjectController.text.trim(),
                  roomNumber: _roomController.text.trim().isEmpty
                      ? null
                      : _roomController.text.trim(),
                  professorName: _professorController.text.trim().isEmpty
                      ? null
                      : _professorController.text.trim(),
                  startTimeHour: _startTime.hour,
                  startTimeMinute: _startTime.minute,
                  endTimeHour: _endTime.hour,
                  endTimeMinute: _endTime.minute,
                  dayOfWeek: day,
                  colorValue: _selectedColor.value,
                );
                widget.repo.addSession(newClass);
              }
              Navigator.pop(context);
            }
          },
          child: const Text('Add Class'),
        ),
      ],
    );
  }
}
