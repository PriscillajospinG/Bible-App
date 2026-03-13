import 'package:flutter/material.dart';

/// Renders a numbered list of prayer-starter sentences.
class PrayerPointList extends StatelessWidget {
  const PrayerPointList({super.key, required this.prayers});

  final List<String> prayers;

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.volunteer_activism_outlined,
                  size: 16, color: Color(0xFF6B4226)),
              const SizedBox(width: 6),
              Text(
                'PRAYER POINTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.brown.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...prayers.asMap().entries.map(
              (e) => _PrayerPointTile(index: e.key + 1, text: e.value),
            ),
      ],
    );
  }
}

class _PrayerPointTile extends StatelessWidget {
  const _PrayerPointTile({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered circle
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF0E9D2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B4226),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF3B2A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
