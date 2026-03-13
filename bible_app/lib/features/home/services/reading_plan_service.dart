import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReadingPlanDay {
  const ReadingPlanDay({
    required this.day,
    required this.book,
    required this.chapter,
  });

  final int day;
  final String book;
  final int chapter;

  Map<String, dynamic> toJson() => {
        'day': day,
        'book': book,
        'chapter': chapter,
      };
}

class ReadingPlan {
  const ReadingPlan({required this.name, required this.days});

  final String name;
  final List<ReadingPlanDay> days;

  int get totalDays => days.length;
}

class ReadingPlanProgress {
  const ReadingPlanProgress({
    required this.planName,
    required this.completedDays,
  });

  final String planName;
  final int completedDays;

  Map<String, dynamic> toJson() => {
        'plan_name': planName,
        'completed_days': completedDays,
      };

  factory ReadingPlanProgress.fromJson(Map<String, dynamic> json) {
    return ReadingPlanProgress(
      planName: json['plan_name'] as String,
      completedDays: json['completed_days'] as int,
    );
  }
}

/// Offline reading plan catalog and local completion tracking.
class ReadingPlanService {
  static const _progressKey = 'reading_plan_progress';

  static final ReadingPlan gospel30 = ReadingPlan(
    name: '30 Day Gospel Plan',
    days: List.generate(30, (i) {
      if (i < 10) {
        return ReadingPlanDay(day: i + 1, book: 'Matthew', chapter: i + 1);
      }
      if (i < 18) {
        return ReadingPlanDay(day: i + 1, book: 'Mark', chapter: i - 9);
      }
      if (i < 25) {
        return ReadingPlanDay(day: i + 1, book: 'Luke', chapter: i - 17);
      }
      return ReadingPlanDay(day: i + 1, book: 'John', chapter: i - 24);
    }),
  );

  static final ReadingPlan newTestament90 = ReadingPlan(
    name: '90 Day New Testament',
    days: List.generate(
      90,
      (i) => ReadingPlanDay(
        day: i + 1,
        book: i < 28
            ? 'Matthew'
            : i < 44
                ? 'Mark'
                : i < 68
                    ? 'Luke'
                    : 'John',
        chapter: (i % 28) + 1,
      ),
    ),
  );

  static final ReadingPlan bible365 = ReadingPlan(
    name: '365 Day Bible Plan',
    days: List.generate(
      365,
      (i) => ReadingPlanDay(
        day: i + 1,
        book: i < 31
            ? 'Genesis'
            : i < 62
                ? 'Exodus'
                : i < 93
                    ? 'Psalms'
                    : 'John',
        chapter: (i % 31) + 1,
      ),
    ),
  );

  final List<ReadingPlan> availablePlans = [
    gospel30,
    newTestament90,
    bible365,
  ];

  ReadingPlan get defaultPlan => gospel30;

  Future<ReadingPlanProgress> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey);
    if (raw == null || raw.isEmpty) {
      return ReadingPlanProgress(planName: defaultPlan.name, completedDays: 0);
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ReadingPlanProgress.fromJson(data);
    } catch (_) {
      return ReadingPlanProgress(planName: defaultPlan.name, completedDays: 0);
    }
  }

  Future<void> selectPlan(String planName) async {
    final current = await getProgress();
    final next = ReadingPlanProgress(planName: planName, completedDays: 0);
    if (current.planName == planName) return;
    await _save(next);
  }

  ReadingPlan getPlanByName(String name) {
    return availablePlans.firstWhere(
      (p) => p.name == name,
      orElse: () => defaultPlan,
    );
  }

  Future<ReadingPlanDay> getTodayAssignment() async {
    final progress = await getProgress();
    final plan = getPlanByName(progress.planName);
    final index = progress.completedDays.clamp(0, plan.days.length - 1);
    return plan.days[index];
  }

  Future<double> getProgressPercent() async {
    final progress = await getProgress();
    final plan = getPlanByName(progress.planName);
    if (plan.totalDays == 0) return 0;
    return progress.completedDays / plan.totalDays;
  }

  Future<void> markTodayCompleted() async {
    final progress = await getProgress();
    final plan = getPlanByName(progress.planName);
    final nextDays = (progress.completedDays + 1).clamp(0, plan.totalDays);
    await _save(
      ReadingPlanProgress(planName: progress.planName, completedDays: nextDays),
    );
  }

  Future<void> _save(ReadingPlanProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }
}
