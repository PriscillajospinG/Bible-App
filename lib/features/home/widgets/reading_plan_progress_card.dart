import 'package:flutter/material.dart';

import '../../reading_plan/services/reading_plan_service.dart';

class ReadingPlanProgressCard extends StatelessWidget {
  const ReadingPlanProgressCard({
    super.key,
    required this.plan,
    required this.completedDays,
    required this.todayAssignment,
    required this.onMarkComplete,
  });

  final ReadingPlan plan;
  final int completedDays;
  final ReadingPlanDay todayAssignment;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final progress = plan.totalDays == 0 ? 0.0 : completedDays / plan.totalDays;
    final first = todayAssignment.readings.first;
    final last = todayAssignment.readings.last;
    final readingSummary = todayAssignment.readings.length == 1
        ? '${first.book} ${first.chapter}'
        : '${first.book} ${first.chapter} to ${last.book} ${last.chapter}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3D7C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF3B2A1A),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF2ECE0),
            color: const Color(0xFF6B4226),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedDays / ${plan.totalDays} days completed',
            style: TextStyle(color: Colors.brown.shade600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            'Today: Day ${todayAssignment.day} - $readingSummary',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A3728),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onMarkComplete,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Mark Complete'),
            ),
          ),
        ],
      ),
    );
  }
}
