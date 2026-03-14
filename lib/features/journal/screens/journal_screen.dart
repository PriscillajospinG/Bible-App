import 'package:flutter/material.dart';

import '../../../ai/journal_reflection_service.dart';
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
  bool _isAnalyzing = false;
  JournalReflectionResult? _lastReflection;
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

    // Start reflection analysis in background; shows prayer points when ready
    _analyzeForPrayer(text);
  }

  Future<void> _analyzeForPrayer(String text) async {
    setState(() {
      _isAnalyzing = true;
      _lastReflection = null;
    });
    try {
      final result = await journalReflectionService.analyzeEntry(text);
      if (!mounted) return;
      setState(() {
        _lastReflection = result;
        _isAnalyzing = false;
      });
      _showPrayerSheet(result);
    } catch (_) {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showPrayerSheet(JournalReflectionResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrayerPointsSheet(reflection: result),
    );
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

          const SizedBox(height: 8),

          // Prayer-points status row
          if (_isAnalyzing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6B4226))),
                  const SizedBox(width: 8),
                  Text(
                    'Generating prayer points…',
                    style: TextStyle(
                        fontSize: 12, color: Colors.brown.shade500),
                  ),
                ],
              ),
            )
          else if (_lastReflection != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: () => _showPrayerSheet(_lastReflection!),
                icon: const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: Color(0xFF6B4226)),
                label: const Text(
                  'View prayer points',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF6B4226)),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),

          const SizedBox(height: 8),

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

// ---------------------------------------------------------------------------
// Prayer Points bottom sheet
// ---------------------------------------------------------------------------

class _PrayerPointsSheet extends StatelessWidget {
  const _PrayerPointsSheet({required this.reflection});

  final JournalReflectionResult reflection;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDF6EC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.brown.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Prayer Points',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF6B4226)),
            ),
            if (reflection.emotions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Detected: ${reflection.emotions.join(', ')}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.brown.shade400),
              ),
            ],
            const SizedBox(height: 16),
            ...List.generate(reflection.prayerPoints.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF6B4226),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reflection.prayerPoints[i],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
            if (reflection.verses.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Scriptures',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF6B4226)),
              ),
              const SizedBox(height: 8),
              ...reflection.verses.map(
                (v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.brown.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.reference,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF6B4226),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.text,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
