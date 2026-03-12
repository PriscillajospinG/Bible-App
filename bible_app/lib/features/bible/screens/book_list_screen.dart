import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../widgets/book_list_tile.dart';
import 'chapter_list_screen.dart';

/// Scrollable list of all books within a testament.
class BookListScreen extends StatelessWidget {
  const BookListScreen({
    super.key,
    required this.translation,
    required this.testamentName,
  });

  final String translation;
  final String testamentName;

  @override
  Widget build(BuildContext context) {
    final books = bibleRepo.getBooks(translation, testamentName);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: Text(
          testamentName,
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
              '${books.length} books · $translation',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (_, i) {
          final book = books[i];
          return BookListTile(
            bookName: book.name,
            chapterCount: book.chapters.length,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChapterListScreen(
                  translation: translation,
                  bookName: book.name,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
