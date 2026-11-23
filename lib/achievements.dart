import 'package:flutter/material.dart';

import 'questions.dart';
import 'stages.dart';
import 'store.dart';

/// مفتاح عام لعرض إشعار «إنجاز جديد» من أي مكان.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class Achievement {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final int target;
  final int reward; // لمعات
  final int Function() progress;
  const Achievement({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.target,
    required this.reward,
    required this.progress,
  });
}

/// كل التقدم هنا مشتق من بيانات Store نفسها، فلا حاجة لعدّادات إضافية في الشاشات.
class Achievements {
  static final List<Achievement> all = [
    Achievement(
        id: 'first_step', title: 'أول خطوة', desc: 'اجتز أول مرحلة في ألغاز الذكاء',
        icon: Icons.flag, target: 1, reward: 10,
        progress: () => Store.passedStages('iq_')),
    Achievement(
        id: 'iq_5', title: 'حلّال ألغاز', desc: 'اجتز 5 مراحل في ألغاز الذكاء',
        icon: Icons.psychology, target: 5, reward: 20,
        progress: () => Store.passedStages('iq_')),
    Achievement(
        id: 'easy_done', title: 'سيّد السهل', desc: 'اجتز كل مراحل المستوى السهل',
        icon: Icons.looks_one, target: iqStagesPerTier, reward: 30,
        progress: () => Store.passedStages('iq_easy_')),
    Achievement(
        id: 'medium_done', title: 'سيّد المتوسط', desc: 'اجتز كل مراحل المستوى المتوسط',
        icon: Icons.looks_two, target: iqStagesPerTier, reward: 40,
        progress: () => Store.passedStages('iq_medium_')),
    Achievement(
        id: 'hard_done', title: 'سيّد الصعب', desc: 'اجتز كل مراحل المستوى الصعب',
        icon: Icons.looks_3, target: iqStagesPerTier, reward: 60,
        progress: () => Store.passedStages('iq_hard_')),
    Achievement(
        id: 'three_stars', title: 'ثلاث نجوم', desc: 'احصل على 3 نجوم في مرحلة واحدة',
        icon: Icons.star, target: 1, reward: 15,
        progress: Store.threeStarStages),
    Achievement(
        id: 'stars_30', title: 'جامع النجوم', desc: 'اجمع 30 نجمة',
        icon: Icons.auto_awesome, target: 30, reward: 30,
        progress: Store.totalStars),
    Achievement(
        id: 'streak_3', title: 'ثلاثة أيام', desc: 'العب 3 أيام متتالية',
        icon: Icons.local_fire_department, target: 3, reward: 15,
        progress: () => Store.bestStreak),
    Achievement(
        id: 'streak_7', title: 'أسبوع متواصل', desc: 'العب 7 أيام متتالية',
        icon: Icons.whatshot, target: 7, reward: 40,
        progress: () => Store.bestStreak),
    Achievement(
        id: 'speech_first', title: 'صوت واثق', desc: 'اجتز أول مرحلة في تحدي النطق',
        icon: Icons.mic, target: 1, reward: 10,
        progress: () => Store.passedStages('speech_')),
    Achievement(
        id: 'speech_all', title: 'ناطق ماهر', desc: 'اجتز كل مراحل تحدي النطق',
        icon: Icons.record_voice_over, target: Track.speech.stagesPerTier * Tier.values.length,
        reward: 50, progress: () => Store.passedStages('speech_')),
    Achievement(
        id: 'quick_first', title: 'أول اختبار خاطف', desc: 'أكمل اختباراً خاطفاً',
        icon: Icons.bolt, target: 1, reward: 10,
        progress: () => Store.quickTaken),
    Achievement(
        id: 'quick_5', title: 'متحدٍّ دائم', desc: 'أكمل 5 اختبارات خاطفة',
        icon: Icons.repeat, target: 5, reward: 20,
        progress: () => Store.quickTaken),
    Achievement(
        id: 'quick_75', title: 'عقل استراتيجي', desc: 'حقق مؤشر لمعة 75 فأكثر',
        icon: Icons.emoji_events, target: 75, reward: 40,
        progress: () => Store.bestQuick),
    Achievement(
        id: 'daily_first', title: 'تحدي اليوم', desc: 'أنجز تحدي اليوم مرة',
        icon: Icons.today, target: 1, reward: 10,
        progress: () => Store.dailyCount),
    Achievement(
        id: 'daily_7', title: 'مواظب', desc: 'أنجز تحدي اليوم 7 مرات',
        icon: Icons.event_available, target: 7, reward: 30,
        progress: () => Store.dailyCount),
    Achievement(
        id: 'coins_300', title: 'ثروة لمعات', desc: 'اكسب 300 لمعة',
        icon: Icons.savings, target: 300, reward: 25,
        progress: () => Store.coinsEarned),
  ];

  static bool _busy = false;

  /// يفتح أي إنجاز اكتمل تقدمه، ويضيف مكافأته، ويعرض إشعاراً واحداً.
  /// يُستدعى تلقائياً عند أي تغيير في Store (انظر MainShell).
  static Future<void> check() async {
    if (_busy) return;
    _busy = true;
    try {
      final shown = <Achievement>[];
      // حلقة لأن المكافآت نفسها قد تُكمل إنجازاً آخر
      while (true) {
        final done = Store.unlockedAchievements;
        final fresh = [
          for (final a in all)
            if (!done.contains(a.id) && a.progress() >= a.target) a
        ];
        if (fresh.isEmpty) break;
        final reward = fresh.fold<int>(0, (s, a) => s + a.reward);
        await Store.unlockAchievements([for (final a in fresh) a.id], reward);
        shown.addAll(fresh);
      }
      if (shown.isEmpty) return;
      final reward = shown.fold<int>(0, (s, a) => s + a.reward);
      final text = shown.length == 1
          ? '🏆 إنجاز جديد: ${shown.first.title} (\u200E+$reward لمعة)'
          : '🏆 فتحت ${shown.length} إنجازات جديدة (\u200E+$reward لمعة)';
      rootMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(text, textAlign: TextAlign.center)));
    } finally {
      _busy = false;
    }
  }
}
