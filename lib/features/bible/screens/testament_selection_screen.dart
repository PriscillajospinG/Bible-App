import 'package:flutter/material.dart';

import '../../../core/services/service_locator.dart';
import 'book_list_screen.dart';

/// Shows Old Testament and New Testament as tappable cards.
class TestamentSelectionScreen extends StatelessWidget {
  const TestamentSelectionScreen({super.key, required this.translation});

  final String translation;

  @override
  Widget build(BuildContext context) {
    final testaments = bibleRepo.getTestaments(translation);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: Text(
          translation,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Text(
            'Select Testament',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF4A3728),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            bibleRepo.getFullName(translation),
            style: const TextStyle(color: Color(0xFFBCA08A), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ...testaments.map(
            (t) => _TestamentCard(
              name: t.name,
              bookCount: t.books.length,
              icon: t.name.toLowerCase().contains('old')
                  ? Icons.history_edu_rounded
                  : Icons.auto_stories_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookListScreen(
                    translation: translation,
                    testamentName: t.name,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestamentCard extends StatelessWidget {
  const _TestamentCard({
    required this.name,
    required this.bookCount,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final int bookCount;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B5035), Color(0xFF9C6A45)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$bookCount books',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
