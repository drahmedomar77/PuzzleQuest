import 'package:flutter/material.dart';

import 'questions.dart';
import 'quick_test_screen.dart';
import 'sfx.dart';
import 'stage_map_screen.dart';
import 'stages.dart';
import 'store.dart';
import 'widgets.dart';

String rankFor(int stars) {
  if (stars < 3) return 'مبتدئ 🌱';
  if (stars < 10) return 'فطن 🧠';
  if (stars < 20) return 'لامع ✨';
  if (stars < 32) return 'ذكي جداً 🔥';
  return 'عبقري 👑';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Question _dailyQuestion() {
    final all = allQuestions;
    final day = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
    return all[day % all.length];
  }

  Future<void> _daily(BuildContext context) async {
    if (Store.dailyDone) {
      showSnack(context, 'أنجزت تحدي اليوم، عُد غداً! 🌙');
      return;
    }
    final q = _dailyQuestion();
    final picked = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تحدي اليوم 🔥'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(q.text,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (var i = 0; i < q.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(c, i),
                    child: Text(q.options[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await Store.markDaily();
    if (picked == q.answer) {
      Sfx.correct();
      await Store.addCoins(10);
      if (context.mounted) showSnack(context, 'إجابة صحيحة! +10 لمعات ⚡');
    } else {
      Sfx.wrong();
      if (context.mounted) {
        showSnack(context, 'الإجابة الصحيحة: ${q.options[q.answer]}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'لمعة ✨',
      showBanner: false, // البانر الوحيد في الشريط السفلي (MainShell)
      actions: const [_SoundButton()],
      body: ValueListenableBuilder<int>(
        valueListenable: Store.tick,
        builder: (context, _, __) {
          final stars = Store.totalStars();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  StatChip(
                      icon: Icons.bolt, text: '${Store.coins} لمعة', color: kGold),
                  StatChip(
                      icon: Icons.local_fire_department,
                      text: '${Store.streak} يوم متتالي',
                      color: Colors.deepOrangeAccent),
                  StatChip(
                      icon: Icons.star, text: '$stars نجمة', color: Colors.amber),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: Text('مستواك: ${rankFor(stars)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              _BigCard(
                icon: Icons.bolt,
                title: 'الاختبار الخاطف',
                subtitle: Store.bestQuick > 0
                    ? 'أفضل نتيجة: ${Store.bestQuick} • 10 أسئلة بمؤقت'
                    : '10 أسئلة في 3 دقائق • احصل على بطاقة نتيجتك',
                color: const Color(0xFFC2185B),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const QuickTestScreen())),
              ),
              const SizedBox(height: 14),
              _BigCard(
                icon: Icons.psychology,
                title: 'ألغاز الذكاء',
                subtitle: 'أسئلة منطق وأرقام من السهل إلى الصعب',
                color: const Color(0xFF7E57C2),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const StageMapScreen(track: Track.iq))),
              ),
              const SizedBox(height: 14),
              _BigCard(
                icon: Icons.record_voice_over,
                title: 'تحدي النطق',
                subtitle: 'انطق العبارات وسيقيّم التطبيق دقة نطقك',
                color: const Color(0xFF00897B),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const StageMapScreen(track: Track.speech))),
              ),
              const SizedBox(height: 14),
              _BigCard(
                icon: Icons.local_fire_department,
                title: 'تحدي اليوم',
                subtitle: Store.dailyDone
                    ? 'أنجزته اليوم ✅ عُد غداً'
                    : 'سؤال واحد يومياً مقابل 10 لمعات',
                color: const Color(0xFFEF6C00),
                onTap: () => _daily(context),
              ),
              const SizedBox(height: 18),
              const Text(
                'تنبيه: نتائج التطبيق للتسلية والتدريب، وليست اختباراً سريرياً لمعدل الذكاء.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// زر كتم/تشغيل المؤثرات الصوتية
class _SoundButton extends StatelessWidget {
  const _SoundButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Store.tick,
      builder: (context, _, __) => IconButton(
        tooltip: Store.soundOn ? 'كتم الصوت' : 'تشغيل الصوت',
        icon: Icon(Store.soundOn ? Icons.volume_up : Icons.volume_off),
        onPressed: () => Store.setSound(!Store.soundOn),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BigCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.55)]),
        ),
        child: Row(
          children: [
            Icon(icon, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left),
          ],
        ),
      ),
    );
  }
}
