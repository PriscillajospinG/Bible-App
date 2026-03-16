import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/bible_repository.dart';

class ReadingAssignment {
  const ReadingAssignment({required this.book, required this.chapter});

  final String book;
  final int chapter;

  Map<String, dynamic> toJson() => {
        'book': book,
        'chapter': chapter,
      };
}

class ReadingPlanDay {
  const ReadingPlanDay({
    required this.day,
    required this.readings,
  });

  final int day;
  final List<ReadingAssignment> readings;

  // Backward-compatible helpers used by existing UI/navigation code.
  String get book => readings.first.book;
  int get chapter => readings.first.chapter;

  Map<String, dynamic> toJson() => {
        'day': day,
        'readings': readings.map((r) => r.toJson()).toList(),
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

/// Reading plan engine that distributes full-Bible chapters across plan days.
class ReadingPlanService {
  ReadingPlanService({required BibleRepository repository})
      : _repository = repository;

  static const _progressKey = 'reading_plan_progress';
  static const _customPlanDaysKey = 'reading_plan_custom_days';

  static const int _defaultCustomDays = 120;
  static const List<int> _presetDays = [30, 90, 180, 365];

  final BibleRepository _repository;

  int _customDays = _defaultCustomDays;
  List<ReadingAssignment> _allAssignments = const [];

  List<String> get durationOptions => const [
        '30 days',
        '90 days',
        '180 days',
        '365 days',
        'Custom',
      ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customDays = prefs.getInt(_customPlanDaysKey) ?? _defaultCustomDays;
    _allAssignments = _buildCanonicalAssignments();
  }

  List<ReadingPlan> get availablePlans {
    return [
      _buildPlan(30),
      _buildPlan(90),
      _buildPlan(180),
      _buildPlan(365),
      _buildPlan(_customDays, custom: true),
    ];
  }

  ReadingPlan get defaultPlan => _buildPlan(30);

  Future<void> setCustomPlanDays(int days) async {
    _customDays = days.clamp(7, 1500);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customPlanDaysKey, _customDays);
  }

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
    if (current.planName == planName) return;
    await _save(ReadingPlanProgress(planName: planName, completedDays: 0));
  }

  Future<void> selectPlanByDays(int days, {bool custom = false}) async {
    final name = custom ? _planNameForDays(days, custom: true) : _planNameForDays(days);
    if (custom) {
      await setCustomPlanDays(days);
    }
    await selectPlan(name);
  }

  Future<int> getCustomPlanDays() async {
    if (_customDays > 0) return _customDays;
    final prefs = await SharedPreferences.getInstance();
    _customDays = prefs.getInt(_customPlanDaysKey) ?? _defaultCustomDays;
    return _customDays;
  }

  ReadingPlan getPlanByName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('custom')) {
      return _buildPlan(_customDays, custom: true);
    }

    final match = RegExp(r'(\d+)').firstMatch(name);
    final days = int.tryParse(match?.group(1) ?? '');
    if (days == null || days <= 0) return defaultPlan;
    return _buildPlan(days);
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

  List<ReadingAssignment> _buildCanonicalAssignments() {
    final out = <ReadingAssignment>[];
    for (final book in _repository.allBookNames) {
      final chapters =
          _repository.getChapterNumbers(BibleRepository.defaultTranslation, book);
      for (final chapter in chapters) {
        out.add(ReadingAssignment(book: book, chapter: chapter));
      }
    }
    return out;
  }

  ReadingPlan _buildPlan(int days, {bool custom = false}) {
    if (_allAssignments.isEmpty) {
      _allAssignments = _buildCanonicalAssignments();
    }

    final totalAssignments = _allAssignments.length;
    final totalDays = days.clamp(1, totalAssignments);
    final planDays = <ReadingPlanDay>[];

    for (var day = 0; day < totalDays; day++) {
      final start = (day * totalAssignments / totalDays).floor();
      var endExclusive = ((day + 1) * totalAssignments / totalDays).floor();
      if (endExclusive <= start) {
        endExclusive = start + 1;
      }
      if (endExclusive > totalAssignments) {
        endExclusive = totalAssignments;
      }

      final chunk = _allAssignments.sublist(start, endExclusive);
      planDays.add(ReadingPlanDay(day: day + 1, readings: chunk));
    }

    return ReadingPlan(
      name: _planNameForDays(totalDays, custom: custom),
      days: planDays,
    );
  }

  String _planNameForDays(int days, {bool custom = false}) {
    if (custom) return 'Custom Plan ($days days)';
    if (_presetDays.contains(days)) return '$days Day Plan';
    return 'Plan ($days days)';
  }

  Future<void> _save(ReadingPlanProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }
}
