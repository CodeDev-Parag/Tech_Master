import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class NoteRepository {
  static const String _boxName = 'notes_box';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(4)) {
      // NoteAdapter will be generated
    }
    await Hive.openBox<Note>(_boxName);
  }

  Box<Note> _getBox() => Hive.box<Note>(_boxName);

  List<Note> getAllNotes() {
    return _getBox().values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> addNote(Note note) async {
    await _getBox().put(note.id, note);
  }

  Future<void> updateNote(Note note) async {
    await _getBox().put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _getBox().delete(id);
  }

  Future<void> clearAll() async {
    await _getBox().clear();
  }
}
