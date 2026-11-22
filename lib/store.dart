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
    await _p.setString('last_day', today);
  }

  static int get streak => _p.getInt('streak') ?? 1;

  // ---------- النجوم ----------
  static int stars(String key) => _p.getInt('stars_$key') ?? 0;

  static Future<void> setStars(String key, int value) async {
    if (value > stars(key)) {
      await _p.setInt('stars_$key', value);
      tick.value++;
    }
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

  static Future<void> addCoins(int n) async {
    await _p.setInt('coins', coins + n);
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

  static Future<void> markDaily() async {
    await _p.setString('daily', _dayKey(DateTime.now()));
    tick.value++;
  }
}
