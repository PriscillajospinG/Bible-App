import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/service_locator.dart';
import '../../data/models/panic_response.dart';
import 'panic_history_screen.dart';
import 'services/semantic_panic_search_service.dart';
import 'services/text_processing_service.dart';
import 'widgets/panic_input_field.dart';
import 'widgets/panic_response_card.dart';

/// Main Spiritual Guidance (Panic Button) screen.
///
/// Step 5 upgrades over Step 2:
///   • Uses [SemanticPanicSearchService] with canonical/stem matching.
///   • Auto-saves every session to [PanicHistoryService].
///   • "Copy response" — copies formatted guidance text to clipboard.
///   • Verse chips are tappable and open [_VerseBottomSheet].
///   • History icon in the AppBar navigates to [PanicHistoryScreen].
class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key, required this.searchService});

  final SemanticPanicSearchService searchService;

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  final _controller = TextEditingController();
  final _scrollKey = GlobalKey();

  PanicResponse? _result;
  bool _isLoading = false;
  String? _error;
  bool _savedToHistory = false;
  String? _aiFormattedResponse;
  bool _isFormatting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what you\'re feeling first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
      _savedToHistory = false;
      _aiFormattedResponse = null;
      _isFormatting = false;
    });

    // Yield one frame so the loading indicator renders before the scoring loop.
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    try {
      final response = widget.searchService.findBestResponse(message);

      // Auto-save session to history.
      await panicHistoryService.saveEntry(message, response.id);

      setState(() {
        _result = response;
        _isLoading = false;
        _savedToHistory = true;
        _isFormatting = true;
      });

      try {
        final formatted = await gemmaModelService.generateResponse(
          userMessage: message,
          panicResponse: response,
        );
        if (!mounted) return;
        setState(() {
          _aiFormattedResponse = formatted;
          _isFormatting = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _aiFormattedResponse = null;
          _isFormatting = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted && _scrollKey.currentContext != null) {
        Scrollable.ensureVisible(
          _scrollKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
      _savedToHistory = false;
      _aiFormattedResponse = null;
      _isFormatting = false;
    });
    _controller.clear();
  }

  void _copyResponse() {
    if (_result == null) return;
    final text = _formatForClipboard(_result!);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openVerse(String verseRef) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VerseBottomSheet(verseRef: verseRef),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PanicHistoryScreen()),
    );
  }

  static String _formatForClipboard(PanicResponse r) {
    final c = r.response;
    final verses = c.recommendedVerses.join('\n');
    return '''
Understanding the Situation
"${c.understandingUserQuery}"

Biblical Explanation
${c.biblicalExplanation}

Biblical Story Example
${c.biblicalStoryExample}

Recommended Verses
$verses

Short Prayer
${c.shortPrayer}
'''.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text(
          'Spiritual Guidance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Guidance history',
          ),
          if (_result != null)
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white70, size: 18),
              label: const Text('New',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 20),
              PanicInputField(
                controller: _controller,
                onSubmit: _search,
                isLoading: _isLoading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _error!),
              ],
              if (_result != null) ...[
                const SizedBox(height: 28),
                const _ResultDivider(),
                const SizedBox(height: 16),
                _UserMessageBubble(message: _controller.text.trim()),
                const SizedBox(height: 12),
                _AiRewriteCard(
                  text: _aiFormattedResponse,
                  isLoading: _isFormatting,
                ),
                const SizedBox(height: 16),
                SizedBox(key: _scrollKey, height: 0),
                PanicResponseCard(
                  panicResponse: _result!,
                  onVerseTap: _openVerse,
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  onCopy: _copyResponse,
                  savedToHistory: _savedToHistory,
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDD8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4C4A0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.church_rounded,
            size: 42,
            color: Color(0xFF6B4226),
          ),
          const SizedBox(height: 10),
          Text(
            'You are not alone.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A3728),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          const Text(
            "Share what you're feeling.\nGod's Word has guidance for you.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7A6A5A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDivider extends StatelessWidget {
  const _ResultDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD4C4A0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "GOD'S WORD FOR YOU",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade400,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD4C4A0))),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── New widgets (Step 5) ──────────────────────────────────────────────────────

/// Bubble showing the user's message above the response card.
class _UserMessageBubble extends StatelessWidget {
  const _UserMessageBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF6B4226),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

/// Row of action buttons shown below the response card.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onCopy, required this.savedToHistory});

  final VoidCallback onCopy;
  final bool savedToHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy'),
          style: FilledButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        if (savedToHistory)
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 15,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                'Saved to history',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AiRewriteCard extends StatelessWidget {
  const _AiRewriteCard({required this.text, required this.isLoading});

  final String? text;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5E1A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: Color(0xFF33691E)),
              SizedBox(width: 6),
              Text(
                'Pastoral Rewrite (Gemma Local)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF33691E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Formatting response locally...'),
              ],
            )
          else
            Text(
              text ??
                  'Local AI formatting unavailable. Structured guidance is shown below.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF2E2E2E),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet that looks up a verse from KJV and displays it with options.
class _VerseBottomSheet extends StatefulWidget {
  const _VerseBottomSheet({required this.verseRef});

  final String verseRef;

  @override
  State<_VerseBottomSheet> createState() => _VerseBottomSheetState();
}

class _VerseBottomSheetState extends State<_VerseBottomSheet> {
  String? _verseText;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    final parsed = TextProcessingService.parseVerseRef(widget.verseRef);
    if (parsed == null) {
      setState(() {
        _error = 'Could not parse verse reference.';
        _loading = false;
      });
      return;
    }

    try {
      final verse = bibleRepo.getVerse(
        'KJV',
        parsed.book,
        parsed.chapter,
        parsed.verse,
      );
      setState(() {
        _verseText = verse?.text;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Verse not found in the local database.';
        _loading = false;
      });
    }
  }

  void _copyVerse() {
    if (_verseText == null) return;
    Clipboard.setData(
      ClipboardData(text: '${widget.verseRef}\n"$_verseText"'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verse copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openInBible() {
    // Signal HomeScreen to switch to the Bible tab (index 1).
    tabSwitchRequest.value = 1;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.verseRef,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B4226),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Text(_error!,
                style: TextStyle(color: theme.colorScheme.error))
          else
            Text(
              '"$_verseText"',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          const SizedBox(height: 20),
          if (!_loading && _error == null) ...[
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _copyVerse,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy verse'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _openInBible,
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Open in Bible'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4226),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
