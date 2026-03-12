import 'package:flutter/material.dart';

/// Placeholder for the Journal feature (Step 4).
class JournalPlaceholderScreen extends StatelessWidget {
  const JournalPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        title: const Text(
          'Journal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDD8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4C4A0), width: 2),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 52,
                color: Color(0xFF6B4226),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Journal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A3728),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming in Step 4.',
              style: TextStyle(fontSize: 15, color: Color(0xFFBCA08A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Write and save your personal reflections.',
              style: TextStyle(fontSize: 13, color: Color(0xFFBCA08A)),
            ),
          ],
        ),
      ),
    );
  }
}
