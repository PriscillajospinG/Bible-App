import 'package:flutter/material.dart';

import '../../../data/models/bible_verse.dart';
import '../services/bible_search_service.dart';
import 'verse_reader_screen.dart';

class BibleSearchScreen extends StatefulWidget {
  const BibleSearchScreen({super.key, required this.searchService});

  final BibleSearchService searchService;

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  final _controller = TextEditingController();
  List<BibleVerse> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(() {
      _results = widget.searchService.searchVerses(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text('Search Bible'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _controller,
              hintText: 'Search words or phrases (love, peace, fear...)',
              leading: const Icon(Icons.search_rounded),
              onSubmitted: (_) => _runSearch(),
              trailing: [
                IconButton(
                  onPressed: _runSearch,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text(
                      'No results yet. Enter a search term.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final v = _results[i];
                      final ref = '${v.book} ${v.chapter}:${v.verse}';
                      final preview = v.text.length > 140
                          ? '${v.text.substring(0, 140)}...'
                          : v.text;
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
                        leading: const Icon(Icons.menu_book_rounded),
                        title: Text(
                          ref,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '$preview\n(${v.translation})',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
