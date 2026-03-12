import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../../../data/models/favorite_verse.dart';
import '../../../data/models/bible_verse.dart';

/// A single verse row inside [VerseReaderScreen].
///
/// - Tap the row to toggle the golden highlight (managed by parent).
/// - Tap the bookmark icon to persist to/from [FavoritesService].
class VerseTile extends StatefulWidget {
  const VerseTile({
    super.key,
    required this.verse,
    required this.translation,
    required this.bookName,
    required this.chapterNumber,
    required this.isHighlighted,
    required this.onTap,
  });

  final BibleVerse verse;
  final String translation;
  final String bookName;
  final int chapterNumber;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  State<VerseTile> createState() => _VerseTileState();
}

class _VerseTileState extends State<VerseTile> {
  late bool _isFavorite;

  String get _id => FavoriteVerse.buildId(
        widget.translation,
        widget.bookName,
        widget.chapterNumber,
        widget.verse.verse,
      );

  @override
  void initState() {
    super.initState();
    _isFavorite = favoritesService.isFavorite(_id);
  }

  Future<void> _toggleFavorite() async {
    final fv = FavoriteVerse(
      id: _id,
      translation: widget.translation,
      book: widget.bookName,
      chapter: widget.chapterNumber,
      verse: widget.verse.verse,
      text: widget.verse.text,
      savedAt: DateTime.now(),
    );
    await favoritesService.toggleFavorite(fv);
    if (mounted) setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      color: widget.isHighlighted
          ? const Color(0xFFFFF9C4)
          : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse number
              SizedBox(
                width: 30,
                child: Text(
                  '${widget.verse.verse}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF6B4226),
                    height: 2.0,
                  ),
                ),
              ),
              // Verse text
              Expanded(
                child: Text(
                  widget.verse.text,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.75,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              // Bookmark icon
              GestureDetector(
                onTap: _toggleFavorite,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      key: ValueKey(_isFavorite),
                      size: 20,
                      color: _isFavorite
                          ? const Color(0xFF6B4226)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
