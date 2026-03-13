import 'package:flutter/material.dart';

import '../../../data/models/bible_verse.dart';

class VerseTile extends StatelessWidget {
  const VerseTile({
    super.key,
    required this.verse,
    required this.translation,
    required this.bookName,
    required this.chapterNumber,
    required this.highlightColor,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onChooseHighlight,
    required this.onShare,
    required this.fontScale,
    required this.highContrast,
    required this.largeVerseText,
  });

  final BibleVerse verse;
  final String translation;
  final String bookName;
  final int chapterNumber;
  final Color? highlightColor;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onChooseHighlight;
  final VoidCallback onShare;
  final double fontScale;
  final bool highContrast;
  final bool largeVerseText;

  @override
  Widget build(BuildContext context) {
    final verseFontSize = (largeVerseText ? 20.0 : 17.0) * fontScale;
    final verseColor = highContrast
        ? Theme.of(context).colorScheme.onSurface
        : const Color(0xFF1A1A1A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      color: highlightColor ?? Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${verse.verse}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF6B4226),
                  height: 2.0,
                ),
              ),
            ),
            Expanded(
              child: Text(
                verse.text,
                style: TextStyle(
                  fontSize: verseFontSize,
                  height: 1.75,
                  color: verseColor,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Verse actions',
              onSelected: (value) {
                if (value == 'bookmark') onToggleBookmark();
                if (value == 'highlight') onChooseHighlight();
                if (value == 'share') onShare();
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'bookmark',
                  child: Row(
                    children: [
                      Icon(
                        isBookmarked
                            ? Icons.bookmark_remove_rounded
                            : Icons.bookmark_add_rounded,
                        size: 18,
                        color: const Color(0xFF6B4226),
                      ),
                      const SizedBox(width: 10),
                      Text(isBookmarked ? 'Remove bookmark' : 'Bookmark verse'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'highlight',
                  child: Row(
                    children: [
                      Icon(Icons.highlight_rounded,
                          size: 18, color: Color(0xFF6B4226)),
                      SizedBox(width: 10),
                      Text('Highlight color'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.ios_share_rounded,
                          size: 18, color: Color(0xFF6B4226)),
                      SizedBox(width: 10),
                      Text('Share card'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 4),
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.more_horiz_rounded,
                  size: 20,
                  color:
                      isBookmarked ? const Color(0xFF6B4226) : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
