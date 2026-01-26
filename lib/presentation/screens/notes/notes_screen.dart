import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../../data/models/note.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Notes',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: notes.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _buildNoteCard(context, ref, theme, note);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteEditor(context, ref),
        label: const Text('Add Note'),
        icon: const Icon(Iconsax.add_square),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.note_1, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to start capturing your thoughts',
            style: GoogleFonts.inter(color: theme.disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
      BuildContext context, WidgetRef ref, ThemeData theme, Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          note.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Updated ${note.updatedAt.toString().split('.')[0]}',
              style:
                  GoogleFonts.inter(fontSize: 12, color: theme.disabledColor),
            ),
          ],
        ),
        onTap: () => _openNoteEditor(context, ref, note: note),
        trailing: IconButton(
          icon: const Icon(Iconsax.trash, color: Colors.redAccent),
          onPressed: () => ref.read(notesProvider.notifier).deleteNote(note.id),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  void _openNoteEditor(BuildContext context, WidgetRef ref, {Note? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(note: note),
    );
  }
}

class NoteEditor extends ConsumerStatefulWidget {
  final Note? note;
  const NoteEditor({super.key, this.note});

  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) return;

    if (widget.note == null) {
      final newNote = Note(
        id: const Uuid().v4(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ref.read(notesProvider.notifier).addNote(newNote);
    } else {
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      ref.read(notesProvider.notifier).updateNote(updatedNote);
    }
    Navigator.pop(context);
  }

  Future<void> _exportAsImage() async {
    final capturedImage = await _screenshotController.captureFromWidget(
      _buildExportWidget(),
    );
    await ref.read(noteExportServiceProvider).exportToImage(
          capturedImage,
          _titleController.text,
        );
  }

  Future<void> _exportAsPdf() async {
    final note = Note(
      id: 'temp',
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ref.read(noteExportServiceProvider).exportToPdf(note);
  }

  Widget _buildExportWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tech Master Notes',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _titleController.text,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Divider(height: 40),
          Text(
            _contentController.text,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHandle(theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Note Title',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  style: GoogleFonts.inter(fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          _buildToolbar(theme),
        ],
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _exportAsImage,
            icon: const Icon(Iconsax.image),
            tooltip: 'Export as Image',
          ),
          IconButton(
            onPressed: _exportAsPdf,
            icon: const Icon(Iconsax.document),
            tooltip: 'Export as PDF',
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }
}
