import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../widgets/translation_tile.dart';
import 'bible_search_screen.dart';
import 'bookmarks_screen.dart';
import 'testament_selection_screen.dart';

/// Entry point for the Bible reader.
///
/// Lists all available translations. KJV is pre-loaded; others are lazy-loaded
/// when the user taps them.
class TranslationSelectionScreen extends StatefulWidget {
  const TranslationSelectionScreen({super.key});

  @override
  State<TranslationSelectionScreen> createState() =>
      _TranslationSelectionScreenState();
}

class _TranslationSelectionScreenState
    extends State<TranslationSelectionScreen> {
  String? _loadingTranslation;

  Future<void> _onTap(String code) async {
    if (_loadingTranslation != null) return;

    if (!bibleRepo.isLoaded(code)) {
      setState(() => _loadingTranslation = code);
      try {
        await bibleRepo.ensureLoaded(code);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not load $code. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _loadingTranslation = null);
        }
        return;
      }
      if (mounted) setState(() => _loadingTranslation = null);
    }

    if (mounted) {
      await settingsService.savePreferredTranslation(code);
      appPreferencesNotifier.value++;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TestamentSelectionScreen(translation: code),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = bibleRepo.getTranslations();
    final preferred = settingsService.preferredTranslation;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text(
          'Bible',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Search Bible',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      BibleSearchScreen(searchService: bibleSearchService),
                ),
              );
            },
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Bookmarks',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarksScreen()),
              );
            },
            icon: const Icon(Icons.bookmark_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.star_rounded, color: Color(0xFF6B4226)),
                title: Text('Preferred: $preferred'),
                subtitle: const Text('Quickly open your preferred translation'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _onTap(preferred),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: translations.length,
              itemBuilder: (_, i) {
                final code = translations[i];
                return TranslationTile(
                  translationCode: code,
                  fullName: code == preferred
                      ? '${bibleRepo.getFullName(code)}  • Preferred'
                      : bibleRepo.getFullName(code),
                  isLoaded: bibleRepo.isLoaded(code),
                  isLoading: _loadingTranslation == code,
                  onTap: () => _onTap(code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF6B4226),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a Translation',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Select which version of the Bible you want to read.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          SizedBox(height: 6),
        ],
      ),
    );
  }
}
