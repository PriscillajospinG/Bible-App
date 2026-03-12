import 'package:flutter/material.dart';

/// Square tile showing a chapter number on [ChapterListScreen].
class ChapterTile extends StatelessWidget {
  const ChapterTile({
    super.key,
    required this.chapterNumber,
    required this.onTap,
  });

  final int chapterNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5EDD8),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '$chapterNumber',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF6B4226),
            ),
          ),
        ),
      ),
    );
  }
}
