import 'package:flutter/material.dart';

import '../models/verse_of_day.dart';

/// Displays the day's verse suggestion with its reference.
class VerseOfDayCard extends StatelessWidget {
  const VerseOfDayCard({super.key, required this.verse});

  final VerseOfDay verse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4226), Color(0xFF8B5E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4226).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined,
                  color: Color(0xFFF5DEB3), size: 16),
              const SizedBox(width: 6),
              Text(
                'VERSE FOR TODAY',
                style: TextStyle(
                  color: const Color(0xFFF5DEB3).withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Verse text
          Text(
            '"${verse.cleanText}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.65,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // Reference
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${verse.reference}',
              style: const TextStyle(
                color: Color(0xFFF5DEB3),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
