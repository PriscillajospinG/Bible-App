import 'package:flutter/material.dart';

import '../../../data/models/panic_response.dart';

/// Displays the full structured response from the panic dataset.
///
/// Sections rendered:
///   • Understanding the Situation
///   • Biblical Explanation
///   • Biblical Story Example
///   • Recommended Verses  (chip row)
///   • Short Prayer        (highlighted gradient card)
class PanicResponseCard extends StatelessWidget {
  const PanicResponseCard({super.key, required this.panicResponse});

  final PanicResponse panicResponse;

  @override
  Widget build(BuildContext context) {
    final r = panicResponse.response;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          icon: Icons.favorite_border_rounded,
          title: 'Understanding the Situation',
          body: r.understandingUserQuery,
          iconColor: const Color(0xFFC0392B),
        ),
        _Section(
          icon: Icons.menu_book_rounded,
          title: 'Biblical Explanation',
          body: r.biblicalExplanation,
          iconColor: const Color(0xFF8E44AD),
        ),
        _Section(
          icon: Icons.history_edu_rounded,
          title: 'Biblical Story Example',
          body: r.biblicalStoryExample,
          iconColor: const Color(0xFF2980B9),
        ),
        _VerseSection(verses: r.recommendedVerses),
        _PrayerSection(prayer: r.shortPrayer),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADFD0)),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF4A3728),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseSection extends StatelessWidget {
  const _VerseSection({required this.verses});

  final List<String> verses;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADFD0)),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bookmark_rounded,
                  color: Color(0xFF27AE60), size: 18),
              SizedBox(width: 8),
              Text(
                'Recommended Verses',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF4A3728),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: verses
                .map(
                  (v) => Chip(
                    label: Text(
                      v,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A3728),
                      ),
                    ),
                    backgroundColor: const Color(0xFFF0E9D2),
                    side: const BorderSide(color: Color(0xFFD4C4A0)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PrayerSection extends StatelessWidget {
  const _PrayerSection({required this.prayer});

  final String prayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4226), Color(0xFF8B5A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.volunteer_activism_rounded,
                  color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Short Prayer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prayer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
