import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'ads.dart';
import 'questions.dart';
import 'quick_logic.dart';
import 'result_card.dart';
import 'sfx.dart';
import 'store.dart';
import 'widgets.dart';

enum _Stage { intro, play, result }

/// الاختبار الخاطف: مقدّمة ← 10 أسئلة بمؤقت ← بطاقة نتيجة قابلة للمشاركة.
class QuickTestScreen extends StatefulWidget {
  const QuickTestScreen({super.key});

  @override
  State<QuickTestScreen> createState() => _QuickTestScreenState();
}

class _QuickTestScreenState extends State<QuickTestScreen> {
  _Stage _stage = _Stage.intro;
  List<QuickQuestion> _qs = [];
  final List<QuickAnswer> _answers = [];
  final Stopwatch _watch = Stopwatch();
  Timer? _timer;
  int _i = 0;
  QuickResult? _result;
  bool _newBest = false;
  int _coins = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _qs = buildQuickTest();
    _answers.clear();
    _i = 0;
    _result = null;
    setState(() => _stage = _Stage.play);
    _beginQuestion();
  }

  void _beginQuestion() {
    _timer?.cancel();
    _watch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (_watch.elapsedMilliseconds >= _qs[_i].tier.seconds * 1000) {
        _submit(-1); // انتهى الوقت
      } else {
        setState(() {});
      }
    });
  }

  void _submit(int picked) {
    if (_stage != _Stage.play) return;
    // يمنع نقرة مزدوجة عرضية من الإجابة على السؤال التالي
    if (picked != -1 && _watch.elapsedMilliseconds < 300) return;
    _timer?.cancel();
    _watch.stop();
    final q = _qs[_i];
    final limit = q.tier.seconds.toDouble();
    _answers.add(QuickAnswer(
      tier: q.tier,
      skill: q.skill,
      correct: picked == q.answer,
      seconds: min(_watch.elapsedMilliseconds / 1000.0, limit),
    ));
    if (_i + 1 >= _qs.length) {
      _finish();
    } else {
      setState(() => _i++);
      _beginQuestion();
    }
  }

  Future<void> _finish() async {
    final r = scoreQuick(_answers);
    final coins = 5 + r.index ~/ 10;
    final isBest = await Store.recordQuick(r.index);
    await Store.addCoins(coins);
    if (!mounted) return;
    setState(() {
      _result = r;
      _newBest = isBest;
      _coins = coins;
      _stage = _Stage.result;
    });
    Sfx.finish();
    Ads.stageFinished();
  }

  Future<void> _share() async {
    final r = _result;
    if (r == null) return;
    final text = StringBuffer(
        'حصلت على ${r.index}/100 في مؤشر $kBrand (${r.band}). هل تستطيع هزيمتي؟ ✨');
    if (kShareLink.isNotEmpty) text.write('\n$kShareLink');
    try {
      await shareResultCard(r, text.toString());
    } catch (_) {
      if (mounted) showSnack(context, 'تعذّرت المشاركة، حاول مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.intro:
        return AppScaffold(title: 'الاختبار الخاطف ⚡', body: _intro());
      case _Stage.play:
        // نخفي البانر أثناء الأسئلة حتى لا تحدث نقرات إعلانية عرضية
        return AppScaffold(
            title: 'الاختبار الخاطف ⚡', showBanner: false, body: _play());
      case _Stage.result:
        return AppScaffold(title: 'نتيجتك', body: _resultView());
    }
  }

  Widget _intro() {
    final best = Store.bestQuick;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        const Center(child: Text('⚡', style: TextStyle(fontSize: 72))),
        const SizedBox(height: 12),
        const Text('اختبار الذكاء الخاطف',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          '$kQuickQuestions أسئلة متدرجة من السهل إلى الصعب، ولكل سؤال وقته '
          '(${Tier.easy.seconds} ثانية للسهل، ${Tier.medium.seconds} للمتوسط، ${Tier.hard.seconds} للصعب).',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, height: 1.6),
        ),
        const SizedBox(height: 8),
        const Text(
          'الإجابة الصحيحة والسريعة ترفع مؤشرك، والأسئلة الصعبة تمنحك نقاطاً أكثر. '
          'في النهاية تحصل على بطاقة نتيجة بنقاط قوتك لتشاركها مع أصدقائك.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white70),
        ),
        if (best > 0) ...[
          const SizedBox(height: 16),
          Center(
              child: StatChip(
                  icon: Icons.emoji_events,
                  text: 'أفضل نتيجة: $best',
                  color: kGold)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _start,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('ابدأ', style: TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'للتسلية والتدريب وليس اختباراً طبياً للذكاء.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _play() {
    final q = _qs[_i];
    final limitMs = q.tier.seconds * 1000;
    final leftMs = (limitMs - _watch.elapsedMilliseconds).clamp(0, limitMs);
    final left = (leftMs / 1000).ceil();
    final urgent = left <= 5;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatChip(
                icon: Icons.help_outline,
                text: 'سؤال ${_i + 1}/${_qs.length}',
                color: q.tier.color),
            StatChip(
                icon: Icons.timer_outlined,
                text: '$left ث',
                color: urgent ? Colors.redAccent : Colors.lightBlueAccent),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (leftMs / limitMs).clamp(0.0, 1.0),
            color: urgent ? Colors.redAccent : q.tier.color,
            backgroundColor: Colors.white12,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: q.tier.color.withValues(alpha: 0.6)),
          ),
          child: Text(q.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, height: 1.5)),
        ),
        const SizedBox(height: 16),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _submit(k),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Text(q.options[k],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resultView() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_newBest)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('رقم قياسي جديد! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent)),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: ResultCardPainter.w / ResultCardPainter.h,
            child: CustomPaint(painter: ResultCardPainter(r)),
          ),
        ),
        const SizedBox(height: 10),
        Text('${r.correct} من ${r.total} إجابات صحيحة',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 8),
        Center(
            child: StatChip(
                icon: Icons.bolt, text: '\u200E+$_coins لمعة', color: kGold)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.ios_share),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('شارك نتيجتك', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _start,
          child: const Text('اختبار جديد'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('الرئيسية'),
        ),
      ],
    );
  }
}
