import 'package:flutter/material.dart';

/// A compact list tile for a Bible book on [BookListScreen].
class BookListTile extends StatelessWidget {
  const BookListTile({
    super.key,
    required this.bookName,
    required this.chapterCount,
    required this.onTap,
  });

  final String bookName;
  final int chapterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEFEAE0), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                bookName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Text(
              '$chapterCount ch.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFBCA08A),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFBCA08A),
            ),
          ],
        ),
      ),
    );
  }
}
