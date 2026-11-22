import 'dart:math';

import 'questions.dart';

/// منطق الاختبار الخاطف: بناء الأسئلة وحساب «مؤشر لمعة». لا يعتمد على الواجهة.

const int kQuickQuestions = 10;

/// ضع هنا رابط التطبيق في Google Play بعد النشر ليُضاف إلى نص المشاركة.
const String kShareLink = '';

const String kBrand = 'لمعة';

/// مهارات الأسئلة. الأسئلة في questions.dart بلا وسم، فنستنتج المهارة من نص السؤال.
enum Skill { patterns, math, language, logic }

/// أسماء محاور الرادار الخمسة، بنفس ترتيب [Skill.values] ثم السرعة.
const List<String> kAxisLabels = [
  'الأنماط',
  'الحساب',
  'اللغة والمعرفة',
  'المنطق',
  'السرعة',
];

Skill skillOf(Question q) {
  final t = q.text;
  bool has(List<String> words) => words.any(t.contains);
  if (has(['العدد التالي', 'العدد الشاذ', '←'])) return Skill.patterns;
  if (has([
    'كلمة', '::', 'عكس كلمة', 'للرؤية', 'يطير', 'الكائنات', 'شكل', 'الشهر', 'أيام الأسبوع',
  ])) {
    return Skill.language;
  }
  if (has(['ترتيبك', 'أطول', 'قطط', 'يتعامد', 'كبيسة', 'فبعد', 'يزداد'])) {
    return Skill.logic;
  }
  return Skill.math;
}

class QuickQuestion {
  final Tier tier;
  final Skill skill;
  final String text;
  final List<String> options;
  final int answer;
  const QuickQuestion({
    required this.tier,
    required this.skill,
    required this.text,
    required this.options,
    required this.answer,
  });
}

/// خطة الاختبار: 3 سهلة ثم 4 متوسطة ثم 3 صعبة، مع تنويع المهارات.
const List<(Tier, Skill)> _plan = [
  (Tier.easy, Skill.patterns),
  (Tier.easy, Skill.language),
  (Tier.easy, Skill.math),
  (Tier.medium, Skill.patterns),
  (Tier.medium, Skill.math),
  (Tier.medium, Skill.language),
  (Tier.medium, Skill.logic),
  (Tier.hard, Skill.patterns),
  (Tier.hard, Skill.logic),
  (Tier.hard, Skill.math),
];

/// يختار أسئلة عشوائية بلا تكرار ويخلط الخيارات، فيختلف كل اختبار عن السابق.
List<QuickQuestion> buildQuickTest([Random? random]) {
  final rnd = random ?? Random();
  final used = <Question>{};
  final result = <QuickQuestion>[];
  for (final (tier, skill) in _plan) {
    final pool = iqQuestions[tier]!;
    var candidates =
        pool.where((q) => !used.contains(q) && skillOf(q) == skill).toList();
    if (candidates.isEmpty) {
      candidates = pool.where((q) => !used.contains(q)).toList();
    }
    final q = candidates[rnd.nextInt(candidates.length)];
    used.add(q);
    final correct = q.options[q.answer];
    final options = [...q.options]..shuffle(rnd);
    result.add(QuickQuestion(
      tier: tier,
      skill: skillOf(q),
      text: q.text,
      options: options,
      answer: options.indexOf(correct),
    ));
  }
  return result;
}

/// إجابة واحدة. إذا انتهى الوقت: correct = false و seconds = زمن المستوى كاملاً.
class QuickAnswer {
  final Tier tier;
  final Skill skill;
  final bool correct;
  final double seconds;
  const QuickAnswer({
    required this.tier,
    required this.skill,
    required this.correct,
    required this.seconds,
  });
}

/// [index] مؤشر لمعة من 0 إلى 100 (للتسلية والتدريب وليس مقياس IQ).
/// [axes] خمس قيم من 0 إلى 100 (null = لم يظهر سؤال من هذه المهارة).
/// [strongest] رقم أقوى محور، أو null إذا كانت كل المحاور أقل من 40.
class QuickResult {
  final int index;
  final int correct;
  final int total;
  final List<int?> axes;
  final String band;
  final int? strongest;
  const QuickResult({
    required this.index,
    required this.correct,
    required this.total,
    required this.axes,
    required this.band,
    required this.strongest,
  });
}

int quickWeight(Tier t) => switch (t) {
      Tier.easy => 1,
      Tier.medium => 2,
      Tier.hard => 3,
    };

/// 1.0 عند الإجابة فوراً، و0.0 عند استهلاك كل الوقت.
double _speed(QuickAnswer a) =>
    (1 - a.seconds / a.tier.seconds).clamp(0.0, 1.0).toDouble();

int _pct(double v) => (v * 100).round().clamp(0, 100).toInt();

String bandFor(int index) {
  if (index >= 90) return 'نابغة اللحظة';
  if (index >= 75) return 'عقل استراتيجي';
  if (index >= 55) return 'محلّل بارع';
  if (index >= 35) return 'عقل متقد';
  return 'مبتدئ متحمّس';
}

/// المؤشر: كل إجابة صحيحة تعطي وزن صعوبتها (1/2/3)، مع خصم حتى 25% لمن يستهلك كل الوقت.
QuickResult scoreQuick(List<QuickAnswer> answers) {
  assert(answers.isNotEmpty);
  var total = 0.0;
  var earned = 0.0;
  for (final a in answers) {
    total += quickWeight(a.tier);
    if (a.correct) earned += quickWeight(a.tier) * (0.75 + 0.25 * _speed(a));
  }
  final index = _pct(earned / total);

  final axes = <int?>[];
  for (final s in Skill.values) {
    final sub = answers.where((a) => a.skill == s).toList();
    if (sub.isEmpty) {
      axes.add(null);
      continue;
    }
    final all = sub.fold<double>(0, (p, a) => p + quickWeight(a.tier));
    final got = sub
        .where((a) => a.correct)
        .fold<double>(0, (p, a) => p + quickWeight(a.tier));
    axes.add(_pct(got / all));
  }
  axes.add(_pct(answers.map(_speed).reduce((a, b) => a + b) / answers.length));

  int? strongest;
  var best = 39; // لا نسمّي نقطة قوة أقل من 40
  for (var i = 0; i < axes.length; i++) {
    final v = axes[i];
    if (v != null && v > best) {
      best = v;
      strongest = i;
    }
  }

  return QuickResult(
    index: index,
    correct: answers.where((a) => a.correct).length,
    total: answers.length,
    axes: axes,
    band: bandFor(index),
    strongest: strongest,
  );
}
