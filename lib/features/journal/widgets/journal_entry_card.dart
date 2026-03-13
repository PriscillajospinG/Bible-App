import 'package:flutter/material.dart';

import '../models/journal_entry.dart';

/// Displays a single [JournalEntry] as a summary card.
class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({super.key, required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final preview = entry.text.length > 160
        ? '${entry.text.substring(0, 160)}…'
        : entry.text;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFFDF8F0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.brown.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + emotion chips
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.brown.shade400),
                const SizedBox(width: 4),
                Text(
                  entry.dateKey,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                ...entry.detectedEmotions.take(3).map((e) => _EmotionChip(e)),
              ],
            ),
            const SizedBox(height: 8),
            // Journal text preview
            Text(
              preview,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF3B2A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  const _EmotionChip(this.emotion);

  final String emotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9D2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        emotion,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF6B4226),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
