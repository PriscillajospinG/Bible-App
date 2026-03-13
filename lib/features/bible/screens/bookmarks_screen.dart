import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../../../data/models/bible_verse.dart';
import 'verse_reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late List<BibleVerse> _bookmarks;

  @override
  void initState() {
    super.initState();
    _bookmarks = bookmarkService.getBookmarks();
  }

  Future<void> _remove(BibleVerse verse) async {
    await bookmarkService.removeBookmark(verse);
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarkService.getBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text('Bookmarks'),
      ),
      body: _bookmarks.isEmpty
          ? const Center(
              child: Text(
                'No bookmarked verses yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: _bookmarks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final v = _bookmarks[i];
                return ListTile(
                  onTap: () {
                    if (v.translation == null || v.book == null || v.chapter == null) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VerseReaderScreen(
                          translation: v.translation!,
                          bookName: v.book!,
                          initialChapter: v.chapter!,
                          initialVerse: v.verse,
                        ),
                      ),
                    );
                  },
                  leading: const Icon(Icons.bookmark_rounded, color: Color(0xFF6B4226)),
                  title: Text(
                    '${v.book} ${v.chapter}:${v.verse} (${v.translation})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    v.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    onPressed: () => _remove(v),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                );
              },
            ),
    );
  }
}
