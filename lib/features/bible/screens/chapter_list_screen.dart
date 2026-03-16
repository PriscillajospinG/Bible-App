import 'package:flutter/material.dart';

import '../../../core/services/service_locator.dart';
import '../widgets/chapter_tile.dart';
import 'verse_reader_screen.dart';

/// Displays all chapter numbers for a book in a scrollable grid.
class ChapterListScreen extends StatelessWidget {
  const ChapterListScreen({
    super.key,
    required this.translation,
    required this.bookName,
  });

  final String translation;
  final String bookName;

  @override
  Widget build(BuildContext context) {
    final chapterNums = bibleRepo.getChapterNumbers(translation, bookName);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: Text(
          bookName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            color: const Color(0xFF5A3420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              '${chapterNums.length} chapter${chapterNums.length == 1 ? '' : 's'} · $translation',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: chapterNums.length,
        itemBuilder: (_, i) {
          final num = chapterNums[i];
          return ChapterTile(
            chapterNumber: num,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerseReaderScreen(
                  translation: translation,
                  bookName: bookName,
                  initialChapter: num,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
