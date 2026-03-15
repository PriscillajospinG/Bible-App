import 'package:flutter/material.dart';

class StreakDisplayCard extends StatelessWidget {
  const StreakDisplayCard({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final ratio = (streak / 30).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3D7C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 3,
                  backgroundColor: const Color(0xFFF2ECE0),
                  color: const Color(0xFF6B4226),
                ),
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFF6B4226),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reading Streak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A3728),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B2A1A),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Keep going',
            style: TextStyle(
              fontSize: 11,
              color: Colors.brown.shade500,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
}
