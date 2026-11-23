import 'dart:async';

import 'package:flutter/material.dart';

import 'ads.dart';
import 'questions.dart';
import 'sfx.dart';
import 'stages.dart';
import 'store.dart';
import 'widgets.dart';

class _Item {
  final String text;
  final List<String> options;
  final int answer;
  final String? explain;
  const _Item(this.text, this.options, this.answer, this.explain);
}

/// نخلط ترتيب الخيارات حتى لا يحفظ اللاعب مكان الإجابة
_Item _shuffled(Question q) {
  final correct = q.options[q.answer];
  final opts = [...q.options]..shuffle();
  return _Item(q.text, opts, opts.indexOf(correct), q.explain);
}

class QuizScreen extends StatefulWidget {
  final StageRef stage;
  const QuizScreen({super.key, required this.stage});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  static const int hintCost = 10;

  late final List<_Item> _items;
  final Set<int> _hidden = {};
  Timer? _timer;
  int _i = 0;
  int _correct = 0;
  int _left = 0;
  int? _picked;
  bool _locked = false;
  bool _done = false;
  bool _inBackground = false; // المؤقت يتوقف أثناء خروج اللاعب من التطبيق
  int _stars = 0;
  int _earned = 0;

  Tier get _tier => widget.stage.tier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _items = [
      for (final q in questionsFor(_tier, widget.stage.index)) _shuffled(q)
    ];
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// مكالمة أو إشعار أو تبديل تطبيق لا يجب أن يُسقط السؤال، فنوقف العدّ حتى العودة.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state != AppLifecycleState.resumed;
  }

  void _startTimer() {
    _timer?.cancel();
    _left = _tier.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _locked || _done || _inBackground) return;
      setState(() => _left--);
      if (_left <= 0) _pick(-1); // انتهى الوقت
    });
  }

  void _pick(int n) {
    if (_locked) return;
    setState(() {
      _locked = true;
      _picked = n;
      if (n == _items[_i].answer) _correct++;
    });
    // مؤثر صوتي: صحيح، أو خاطئ (يشمل انتهاء الوقت)
    if (n == _items[_i].answer) {
      Sfx.correct();
    } else {
      Sfx.wrong();
    }
  }

  void _next() {
    if (_i + 1 >= _items.length) {
      _finish();
      return;
    }
    setState(() {
      _i++;
      _picked = null;
      _locked = false;
      _hidden.clear();
    });
    _startTimer();
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final stars = _correct >= 5 ? 3 : (_correct >= 4 ? 2 : (_correct >= 3 ? 1 : 0));
    final coins = _correct * 2 + stars * 3;
    await Store.setStars(widget.stage.key, stars);
    await Store.addCoins(coins);
    if (!mounted) return;
    setState(() {
      _done = true;
      _stars = stars;
      _earned = coins;
    });
    Ads.stageFinished();
  }

  Future<void> _hint() async {
    if (_locked) return;
    if (await Store.spend(hintCost)) {
      final wrong = [
        for (var k = 0; k < _items[_i].options.length; k++)
          if (k != _items[_i].answer && !_hidden.contains(k)) k
      ]..shuffle();
      if (mounted) setState(() => _hidden.addAll(wrong.take(2)));
    } else {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('لا تكفي اللمعات'),
          content: const Text('شاهد إعلاناً قصيراً لتحصل على 10 لمعات.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                Ads.showRewarded(
                  onReward: () => Store.addCoins(10),
                  onUnavailable: () =>
                      showSnack(context, 'لا يوجد إعلان متاح الآن'),
                );
              },
              child: const Text('شاهد الإعلان'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_tier.label} - مرحلة ${widget.stage.index + 1}';
    if (_done) {
      final next = nextStage(widget.stage);
      return AppScaffold(
        title: title,
        body: StageResult(
          stars: _stars,
          coins: _earned,
          summary: 'أجبت $_correct من ${_items.length} بشكل صحيح',
          onRetry: () => replaceWith(context, widget.stage),
          onNext: next == null ? null : () => replaceWith(context, next),
          onExit: () => Navigator.of(context).pop(),
        ),
      );
    }

    final item = _items[_i];
    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatChip(
                  icon: Icons.help_outline,
                  text: 'سؤال ${_i + 1}/${_items.length}',
                  color: _tier.color),
              StatChip(
                  icon: Icons.timer_outlined,
                  text: '$_left ث',
                  color: _left <= 5 ? Colors.redAccent : Colors.lightBlueAccent),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (_left / _tier.seconds).clamp(0.0, 1.0),
              color: _tier.color,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _tier.color.withValues(alpha: 0.6)),
            ),
            child: Text(item.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, height: 1.5)),
          ),
          const SizedBox(height: 16),
          for (var k = 0; k < item.options.length; k++) _option(item, k),
          const SizedBox(height: 8),
          if (_locked) ...[
            if (_picked == -1)
              const Text('انتهى الوقت ⏰',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            if (item.explain != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('💡 ${item.explain}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.white70)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _next,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(_i + 1 >= _items.length ? 'إنهاء' : 'السؤال التالي',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _hint,
              icon: const Icon(Icons.lightbulb_outline, color: kGold),
              label: Text('تلميح (-$hintCost لمعات)  •  رصيدك ${Store.coins}'),
            ),
        ],
      ),
    );
  }

  Widget _option(_Item item, int k) {
    if (_hidden.contains(k)) {
      return const SizedBox(height: 0);
    }
    Color bg = Colors.white.withValues(alpha: 0.1);
    if (_locked) {
      if (k == item.answer) {
        bg = Colors.green.withValues(alpha: 0.75);
      } else if (k == _picked) {
        bg = Colors.red.withValues(alpha: 0.75);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _locked ? null : () => _pick(k),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(item.options[k],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
