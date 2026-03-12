import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../widgets/verse_tile.dart';

/// Full-screen Bible chapter reader with:
/// - Scrollable verse list with verse numbers
/// - Tap-to-highlight (session-only, golden background)
/// - Bookmark icon per verse (persisted via FavoritesService)
/// - Previous / Next chapter navigation bar at the bottom
class VerseReaderScreen extends StatefulWidget {
  const VerseReaderScreen({
    super.key,
    required this.translation,
    required this.bookName,
    required this.initialChapter,
  });

  final String translation;
  final String bookName;
  final int initialChapter;

  @override
  State<VerseReaderScreen> createState() => _VerseReaderScreenState();
}

class _VerseReaderScreenState extends State<VerseReaderScreen> {
  late int _chapter;
  late List<int> _chapterNums;
  final Set<int> _highlighted = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chapter = widget.initialChapter;
    _chapterNums =
        bibleRepo.getChapterNumbers(widget.translation, widget.bookName);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  bool get _hasPrev =>
      _chapterNums.isNotEmpty && _chapter > _chapterNums.first;

  bool get _hasNext =>
      _chapterNums.isNotEmpty && _chapter < _chapterNums.last;

  void _navigate(int newChapter) {
    setState(() {
      _chapter = newChapter;
      _highlighted.clear();
    });
    _scrollController.jumpTo(0);
  }

  void _goPrev() {
    final idx = _chapterNums.indexOf(_chapter);
    if (idx > 0) _navigate(_chapterNums[idx - 1]);
  }

  void _goNext() {
    final idx = _chapterNums.indexOf(_chapter);
    if (idx >= 0 && idx < _chapterNums.length - 1) {
      _navigate(_chapterNums[idx + 1]);
    }
  }

  // ── Highlighting ────────────────────────────────────────────────────────────

  void _toggleHighlight(int verseNumber) {
    setState(() {
      if (_highlighted.contains(verseNumber)) {
        _highlighted.remove(verseNumber);
      } else {
        _highlighted.add(verseNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final verses =
        bibleRepo.getVerses(widget.translation, widget.bookName, _chapter);
    final chapterIdx = _chapterNums.indexOf(_chapter);
    final totalChapters = _chapterNums.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              '${widget.bookName} $_chapter',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              widget.translation,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Highlighted verse count badge
          if (_highlighted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_highlighted.length}',
                    style: const TextStyle(
                      color: Color(0xFF4A3728),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chapter position strip
          Container(
            color: const Color(0xFF5A3420),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Chapter ${chapterIdx + 1} of $totalChapters',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Verse list
          Expanded(
            child: verses.isEmpty
                ? const Center(
                    child: Text(
                      'No verses found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: verses.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 0.5,
                      indent: 20,
                      endIndent: 20,
                      color: Color(0xFFEFEAE0),
                    ),
                    itemBuilder: (_, i) {
                      final v = verses[i];
                      return VerseTile(
                        verse: v,
                        translation: widget.translation,
                        bookName: widget.bookName,
                        chapterNumber: _chapter,
                        isHighlighted: _highlighted.contains(v.verse),
                        onTap: () => _toggleHighlight(v.verse),
                      );
                    },
                  ),
          ),

          // Previous / Next chapter nav bar
          _ChapterNavBar(
            chapterNumber: _chapter,
            hasPrev: _hasPrev,
            hasNext: _hasNext,
            onPrev: _goPrev,
            onNext: _goNext,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget
// ---------------------------------------------------------------------------

class _ChapterNavBar extends StatelessWidget {
  const _ChapterNavBar({
    required this.chapterNumber,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final int chapterNumber;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EDD8),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous',
            enabled: hasPrev,
            onTap: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Chapter $chapterNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B4226),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next',
            enabled: hasNext,
            onTap: onNext,
            reverseLayout: true,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.reverseLayout = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool reverseLayout;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: reverseLayout
          ? [
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled
                        ? const Color(0xFF6B4226)
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(width: 2),
              Icon(icon,
                  color: enabled
                      ? const Color(0xFF6B4226)
                      : Colors.grey.shade400),
            ]
          : [
              Icon(icon,
                  color: enabled
                      ? const Color(0xFF6B4226)
                      : Colors.grey.shade400),
              const SizedBox(width: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled
                        ? const Color(0xFF6B4226)
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  )),
            ],
    );

    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6B4226),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: content,
    );
  }
}
