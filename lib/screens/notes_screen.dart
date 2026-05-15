import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _controller = TextEditingController();
  bool _hasLoadedInitialNote = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(userNoteNotifierProvider.notifier)
        .saveNote(_controller.text);

    if (!mounted) return;

    final saveState = ref.read(userNoteNotifierProvider);
    final message =
        saveState.hasError ? saveState.error.toString() : 'Note saved';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(userNoteProvider);
    final saveState = ref.watch(userNoteNotifierProvider);
    final isSaving = saveState.isLoading;

    ref.listen(userNoteProvider, (previous, next) {
      next.whenData((note) {
        if (!_hasLoadedInitialNote) {
          _controller.text = note.note;
          _hasLoadedInitialNote = true;
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: isSaving ? null : _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load notes: $error'),
          ),
        ),
        data: (note) {
          if (!_hasLoadedInitialNote) {
            _controller.text = note.note;
            _hasLoadedInitialNote = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              minLines: null,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write a note...',
              ),
            ),
          );
        },
      ),
    );
  }
}
