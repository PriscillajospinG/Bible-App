import 'package:flutter/material.dart';

import '../services/reading_progress_service.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.position,
    required this.onContinue,
  });

  final ReadingPosition? position;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9D2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: position == null
          ? const Text(
              'No recent reading yet. Open Bible to start your journey.',
              style: TextStyle(color: Color(0xFF4A3728)),
            )
          : Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Color(0xFF6B4226)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Continue Reading\n${position!.book} ${position!.chapter} (${position!.translation})',
                    style: const TextStyle(
                      color: Color(0xFF4A3728),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4226),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
    );
  }
}
