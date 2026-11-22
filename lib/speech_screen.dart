import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'ads.dart';
import 'questions.dart';
import 'stages.dart';
import 'store.dart';
import 'widgets.dart';

/// تحويل النص لصيغة موحّدة قبل المقارنة (بدون تشكيل وبهمزات موحّدة)
String normalizeArabic(String s) {
  var t = s.replaceAll(RegExp(r'[ً-ْٰـ]'), '');
  t = t
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  t = t.replaceAll(RegExp(r'[^ء-ي\s]'), ' ');
  return t.replaceAll(RegExp(r'\s+'), '').trim();
}

/// نسبة التشابه بين 0 و 1 (مسافة ليفنشتاين)
double similarity(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final m = a.length, n = b.length;
  var prev = List<int>.generate(n + 1, (j) => j);
  for (var i = 1; i <= m; i++) {
    final cur = List<int>.filled(n + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final del = prev[j] + 1;
      final ins = cur[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      cur[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    prev = cur;
  }
  final dist = prev[n];
  final longest = m > n ? m : n;
  return (1 - dist / longest).clamp(0.0, 1.0);
}

class SpeechScreen extends StatefulWidget {
  final StageRef stage;
  const SpeechScreen({super.key, required this.stage});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  static const double passMark = 0.7;

  final SpeechToText _stt = SpeechToText();
  late final List<String> _phrases;
  late final List<double> _best;
  bool _ready = false;
  bool _initDone = false;
  bool _listening = false;
  String? _locale;
  String _heard = '';
  double? _score; // نتيجة المحاولة الحالية
  int _i = 0;
  bool _done = false;
  int _stars = 0;
  int _earned = 0;

  Tier get _tier => widget.stage.tier;

  @override
  void initState() {
    super.initState();
    _phrases = phrasesFor(_tier, widget.stage.index);
    _best = List<double>.filled(_phrases.length, 0);
    _init();
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    bool ok = false;
    try {
      ok = await _stt.initialize(
        onStatus: _onStatus,
        onError: (e) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (ok) {
        final locales = await _stt.locales();
        final ar = locales
            .where((l) => l.localeId.toLowerCase().startsWith('ar'))
            .toList();
        if (ar.isNotEmpty) {
          _locale = ar
              .firstWhere(
                (l) => l.localeId.toLowerCase().replaceAll('-', '_') == 'ar_sa',
                orElse: () => ar.first,
              )
              .localeId;
        }
      }
    } catch (_) {
      ok = false;
    }
    if (mounted) {
      setState(() {
        _ready = ok;
        _initDone = true;
      });
    }
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') && _listening) {
      if (!mounted) return;
      setState(() => _listening = false);
      if (_score == null) _evaluate();
    }
  }

  Future<void> _start() async {
    if (_listening) return;
    setState(() {
      _heard = '';
      _score = null;
      _listening = true;
    });
    await _stt.listen(
      onResult: _onResult,
      localeId: _locale,
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stop() async {
    await _stt.stop();
  }

  void _onResult(SpeechRecognitionResult r) {
    if (!mounted) return;
    setState(() => _heard = r.recognizedWords);
    if (r.finalResult && _score == null) {
      setState(() => _listening = false);
      _evaluate();
    }
  }

  void _evaluate() {
    final s = similarity(normalizeArabic(_heard), normalizeArabic(_phrases[_i]));
    setState(() {
      _score = s;
      if (s > _best[_i]) _best[_i] = s;
    });
  }

  Future<void> _next() async {
    if (_i + 1 >= _phrases.length) {
      await _finish();
      return;
    }
    setState(() {
      _i++;
      _heard = '';
      _score = null;
    });
  }

  Future<void> _finish() async {
    final passes = _best.where((s) => s >= passMark).length;
    final stars = passes >= 4 ? 3 : (passes == 3 ? 2 : (passes == 2 ? 1 : 0));
    final coins = passes * 3 + stars * 3;
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

  @override
  Widget build(BuildContext context) {
    final title = 'نطق ${_tier.label} - مرحلة ${widget.stage.index + 1}';

    if (_done) {
      final next = nextStage(widget.stage);
      final passes = _best.where((s) => s >= passMark).length;
      return AppScaffold(
        title: title,
        body: StageResult(
          stars: _stars,
          coins: _earned,
          summary: 'نطقت $passes من ${_phrases.length} عبارات بنجاح',
          onRetry: () => replaceWith(context, widget.stage),
          onNext: next == null ? null : () => replaceWith(context, next),
          onExit: () => Navigator.of(context).pop(),
        ),
      );
    }

    if (!_initDone) {
      return AppScaffold(
          title: title,
          body: const Center(child: CircularProgressIndicator()));
    }

    if (!_ready) {
      return AppScaffold(
        title: title,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_off, size: 64, color: Colors.white54),
                const SizedBox(height: 12),
                const Text(
                  'التعرف على الصوت غير متاح.\nتأكد من السماح للتطبيق باستخدام الميكروفون، ومن تثبيت خدمة Google للتعرف على الكلام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, height: 1.6),
                ),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('رجوع')),
              ],
            ),
          ),
        ),
      );
    }

    final score = _score;
    final passed = score != null && score >= passMark;
    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatChip(
                  icon: Icons.record_voice_over,
                  text: 'عبارة ${_i + 1}/${_phrases.length}',
                  color: _tier.color),
              StatChip(
                  icon: Icons.check_circle_outline,
                  text: 'ناجحة ${_best.where((s) => s >= passMark).length}',
                  color: Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 20),
          const Text('اضغط على الميكروفون وانطق العبارة بوضوح:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _tier.color.withValues(alpha: 0.6)),
            ),
            child: Text(_phrases[_i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, height: 1.6)),
          ),
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: _listening ? _stop : _start,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _listening ? 110 : 96,
                height: _listening ? 110 : 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? Colors.redAccent : kGold,
                  boxShadow: [
                    BoxShadow(
                      color: (_listening ? Colors.redAccent : kGold)
                          .withValues(alpha: 0.5),
                      blurRadius: _listening ? 30 : 12,
                    ),
                  ],
                ),
                child: Icon(_listening ? Icons.stop : Icons.mic,
                    size: 48, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(_listening ? 'أستمع إليك...' : 'اضغط للتسجيل',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          if (_heard.isNotEmpty)
            Text('سمعتك تقول: $_heard',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17)),
          if (score != null) ...[
            const SizedBox(height: 14),
            Text(
              score == 0
                  ? 'لم أسمعك جيداً، حاول مرة أخرى 🎤'
                  : passed
                      ? 'ممتاز! دقة النطق ${(score * 100).round()}% ✅'
                      : 'دقة النطق ${(score * 100).round()}% - حاول مجدداً 💪',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.greenAccent : Colors.orangeAccent),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: _start, child: const Text('إعادة المحاولة')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                      onPressed: _next,
                      child: Text(
                          _i + 1 >= _phrases.length ? 'إنهاء' : 'التالية')),
                ),
              ],
            ),
          ] else if (!_listening)
            TextButton(onPressed: _next, child: const Text('تخطي هذه العبارة')),
        ],
      ),
    );
  }
}
