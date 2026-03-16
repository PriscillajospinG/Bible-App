import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/service_locator.dart';
import '../../../data/models/bible_verse.dart';
import '../services/highlight_service.dart';
import '../widgets/verse_share_card.dart';
import '../widgets/verse_tile.dart';

class VerseReaderScreen extends StatefulWidget {
  const VerseReaderScreen({
    super.key,
    required this.translation,
    required this.bookName,
    required this.initialChapter,
    this.initialVerse,
  });

  final String translation;
  final String bookName;
  final int initialChapter;
  final int? initialVerse;

  @override
  State<VerseReaderScreen> createState() => _VerseReaderScreenState();
}

class _VerseReaderScreenState extends State<VerseReaderScreen> {
  late int _chapter;
  late List<int> _chapterNums;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    _chapter = widget.initialChapter;
    _chapterNums =
        bibleRepo.getChapterNumbers(widget.translation, widget.bookName);
    readingProgressService.saveProgress(
      widget.translation,
      widget.bookName,
      _chapter,
    );
    bibleCacheService.prefetchAdjacentChapters(
      widget.translation,
      widget.bookName,
      _chapter,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialVerse != null) {
        _scrollToVerse(widget.initialVerse!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasPrev =>
      _chapterNums.isNotEmpty && _chapter > _chapterNums.first;

  bool get _hasNext =>
      _chapterNums.isNotEmpty && _chapter < _chapterNums.last;

  void _navigate(int newChapter) {
    setState(() {
      _chapter = newChapter;
      _verseKeys.clear();
    });
    readingProgressService.saveProgress(
      widget.translation,
      widget.bookName,
      _chapter,
    );
    bibleCacheService.prefetchAdjacentChapters(
      widget.translation,
      widget.bookName,
      _chapter,
    );
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

  BibleVerse _withContext(BibleVerse verse) {
    return BibleVerse(
      translation: widget.translation,
      book: widget.bookName,
      chapter: _chapter,
      verse: verse.verse,
      text: verse.text,
    );
  }

  Future<void> _toggleBookmark(BibleVerse verse) async {
    final item = _withContext(verse);
    await bookmarkService.toggleBookmark(item);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _chooseHighlight(BibleVerse verse) async {
    final item = _withContext(verse);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _HighlightPickerSheet(current: highlightService.getHighlightColor(item)),
    );

    if (selected == null) return;
    if (selected == 'clear') {
      await highlightService.removeHighlight(item);
    } else {
      final color = HighlightService.supportedColors[selected];
      if (color != null) {
        await highlightService.highlightVerse(item, color);
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openShareDialog(BibleVerse verse) async {
    final item = _withContext(verse);
    final reference = '${item.book} ${item.chapter}:${item.verse}';

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ShareVerseDialog(
        reference: reference,
        text: item.text,
        translation: item.translation ?? widget.translation,
      ),
    );
  }

  void _scrollToVerse(int verseNumber) {
    final key = _verseKeys[verseNumber];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.15,
    );
  }

  int get _chapterHighlightCount {
    final verses =
        bibleCacheService.getChapterVerses(widget.translation, widget.bookName, _chapter);
    var count = 0;
    for (final v in verses) {
      if (highlightService.getHighlightColor(_withContext(v)) != null) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final verses =
      bibleCacheService.getChapterVerses(widget.translation, widget.bookName, _chapter);
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
          if (_chapterHighlightCount > 0)
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
                    '$_chapterHighlightCount',
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
          Container(
            color: const Color(0xFF5A3420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      final data = _withContext(v);
                      _verseKeys.putIfAbsent(v.verse, () => GlobalKey());

                      return Container(
                        key: _verseKeys[v.verse],
                        child: VerseTile(
                          verse: v,
                          translation: widget.translation,
                          bookName: widget.bookName,
                          chapterNumber: _chapter,
                          highlightColor: highlightService.getHighlightColor(data),
                          isBookmarked: bookmarkService.isBookmarked(data),
                          onToggleBookmark: () => _toggleBookmark(v),
                          onChooseHighlight: () => _chooseHighlight(v),
                          onShare: () => _openShareDialog(v),
                          fontScale: accessibilityService.fontScale,
                          highContrast: accessibilityService.highContrast,
                          largeVerseText: accessibilityService.largeVerseText,
                        ),
                      );
                    },
                  ),
          ),
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

class _HighlightPickerSheet extends StatelessWidget {
  const _HighlightPickerSheet({this.current});

  final Color? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Highlight color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: HighlightService.supportedColors.entries.map((entry) {
                final isCurrent =
                    current?.toARGB32() == entry.value.toARGB32();
                return ChoiceChip(
                  selected: isCurrent,
                  label: Text(entry.key),
                  backgroundColor: entry.value,
                  selectedColor: entry.value,
                  labelStyle: const TextStyle(
                    color: Color(0xFF3A2D20),
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => Navigator.of(context).pop(entry.key),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop('clear'),
              icon: const Icon(Icons.layers_clear_rounded),
              label: const Text('Clear highlight'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareVerseDialog extends StatefulWidget {
  const _ShareVerseDialog({
    required this.reference,
    required this.text,
    required this.translation,
  });

  final String reference;
  final String text;
  final String translation;

  @override
  State<_ShareVerseDialog> createState() => _ShareVerseDialogState();
}

class _ShareVerseDialogState extends State<_ShareVerseDialog> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _saveImage() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capturePng(_cardKey);
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/verse_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved image to ${file.path}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capturePng(_cardKey);
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/verse_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.reference,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List?> _capturePng(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: VerseShareCard(
                reference: widget.reference,
                text: widget.text,
                translation: widget.translation,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _saveImage,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save image'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _shareImage,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
