import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي: النجوم، اللمعات (العملة)، سلسلة الأيام، تحدي اليوم
class Store {
  static late SharedPreferences _p;

  /// يزداد عند أي تغيير لتحديث الواجهات
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    await _touchStreak();
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static Future<void> _touchStreak() async {
    final now = DateTime.now();
    final today = _dayKey(now);
    final last = _p.getString('last_day');
    if (last == today) return;
    final yesterday = _dayKey(DateTime(now.year, now.month, now.day - 1));
    final s = last == yesterday ? streak + 1 : 1;
    await _p.setInt('streak', s);
    if (s > (_p.getInt('best_streak') ?? 0)) await _p.setInt('best_streak', s);
    await _p.setString('last_day', today);
  }

  static int get streak => _p.getInt('streak') ?? 1;

  /// أطول سلسلة أيام متتالية
  static int get bestStreak => max(_p.getInt('best_streak') ?? 0, streak);

  // ---------- النجوم ----------
  static int stars(String key) => _p.getInt('stars_$key') ?? 0;

  static Future<void> setStars(String key, int value) async {
    if (value > stars(key)) {
      await _p.setInt('stars_$key', value);
      tick.value++;
    }
  }

  /// عدد المراحل المُجتازة (نجمة فأكثر) التي يبدأ مفتاحها بـ [prefix]، مثل 'iq_easy_'
  static int passedStages(String prefix) {
    var n = 0;
    for (final k in _p.getKeys()) {
      if (k.startsWith('stars_$prefix') && (_p.getInt(k) ?? 0) >= 1) n++;
    }
    return n;
  }

  /// عدد المراحل التي نالت 3 نجوم
  static int threeStarStages() {
    var n = 0;
    for (final k in _p.getKeys()) {
      if (k.startsWith('stars_') && (_p.getInt(k) ?? 0) >= 3) n++;
    }
    return n;
  }

  static int totalStars() {
    var sum = 0;
    for (final k in _p.getKeys()) {
      if (k.startsWith('stars_')) sum += _p.getInt(k) ?? 0;
    }
    return sum;
  }

  // ---------- اللمعات ----------
  static int get coins => _p.getInt('coins') ?? 30;

  /// إجمالي اللمعات التي كسبها اللاعب (لا يُنقص عند الإنفاق)
  static int get coinsEarned => _p.getInt('coins_earned') ?? 0;

  static Future<void> addCoins(int n) async {
    await _p.setInt('coins', coins + n);
    if (n > 0) await _p.setInt('coins_earned', coinsEarned + n);
    tick.value++;
  }

  static Future<bool> spend(int n) async {
    if (coins < n) return false;
    await _p.setInt('coins', coins - n);
    tick.value++;
    return true;
  }

  // ---------- الصوت ----------
  static bool get soundOn => _p.getBool('sound') ?? true;

  static Future<void> setSound(bool v) async {
    await _p.setBool('sound', v);
    tick.value++;
  }

  // ---------- الاختبار الخاطف ----------
  static int get bestQuick => _p.getInt('quick_best') ?? 0;

  static int get quickTaken => _p.getInt('quick_taken') ?? 0;

  /// يسجّل نتيجة اختبار؛ يعيد true فقط إذا كانت رقماً قياسياً جديداً بعد المحاولة الأولى.
  static Future<bool> recordQuick(int index) async {
    final taken = quickTaken;
    final isBest = index > bestQuick;
    await _p.setInt('quick_taken', taken + 1);
    if (isBest) await _p.setInt('quick_best', index);
    tick.value++;
    return isBest && taken > 0;
  }

  // ---------- تحدي اليوم ----------
  static bool get dailyDone => _p.getString('daily') == _dayKey(DateTime.now());

  static int get dailyCount => _p.getInt('daily_count') ?? 0;

  static Future<void> markDaily() async {
    await _p.setString('daily', _dayKey(DateTime.now()));
    await _p.setInt('daily_count', dailyCount + 1);
    tick.value++;
  }

  // ---------- الإنجازات ----------
  static Set<String> get unlockedAchievements =>
      (_p.getStringList('ach') ?? const <String>[]).toSet();

  /// يسجّل إنجازات جديدة ويضيف مكافأتها مباشرة دون احتسابها في «إجمالي المكتسب».
  static Future<void> unlockAchievements(List<String> ids, int reward) async {
    final all = unlockedAchievements..addAll(ids);
    await _p.setStringList('ach', all.toList());
    if (reward > 0) await _p.setInt('coins', coins + reward);
    tick.value++;
  }

  // ---------- إعادة الضبط ----------
  /// يمسح كل التقدم ويُبقي إعداد الصوت.
  static Future<void> resetAll() async {
    final sound = soundOn;
    await _p.clear();
    await _p.setBool('sound', sound);
    await _touchStreak();
    tick.value++;
  }
}
