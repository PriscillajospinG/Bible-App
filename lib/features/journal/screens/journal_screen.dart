import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_input_field.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSaving = false;
  List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadEntries() {
    setState(() {
      _entries = journalRepo.getAllEntries();
    });
  }

  Future<void> _saveEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);

    final emotions = emotionDetectionService.detectEmotions(text);
    final now = DateTime.now();
    final entry = JournalEntry(
      id: now.millisecondsSinceEpoch.toString(),
      dateKey: now.toIso8601String().substring(0, 10),
      text: text,
      detectedEmotions: emotions,
      createdAt: now,
    );

    await journalRepo.saveEntry(entry);

    // Notify TodayScreen to refresh.
    journalRefreshNotifier.value++;

    _controller.clear();
    _focusNode.unfocus();

    _loadEntries();
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved — emotions detected: ${emotions.join(', ')}',
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF6B4226),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Fixed top section: header + input ──────────────────────
            _buildInputSection(),

            // ── Scrollable entries list ────────────────────────────────
            Expanded(child: _buildEntriesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      color: const Color(0xFFFDF8F0),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'My Journal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B2A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Write honestly. God hears every word.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.brown.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),

          // Text field
          JournalInputField(
            controller: _controller,
            focusNode: _focusNode,
          ),
          const SizedBox(height: 10),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveEntry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B4226),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_alt_rounded, size: 18),
              label: Text(
                _isSaving ? 'Saving…' : 'Save Entry',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider with entry count
          if (_entries.isNotEmpty)
            Row(
              children: [
                Expanded(child: Divider(color: Colors.brown.shade100)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${_entries.length} ${_entries.length == 1 ? 'entry' : 'entries'}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.brown.shade400),
                  ),
                ),
                Expanded(child: Divider(color: Colors.brown.shade100)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEntriesList() {
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.book_outlined, size: 48, color: Colors.brown.shade200),
              const SizedBox(height: 12),
              Text(
                'Your journal is empty.\nStart writing today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.brown.shade400,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      itemCount: _entries.length,
      itemBuilder: (context, index) =>
          JournalEntryCard(entry: _entries[index]),
    );
  }
}
