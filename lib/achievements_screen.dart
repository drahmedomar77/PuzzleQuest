import 'package:flutter/material.dart';

import 'achievements.dart';
import 'store.dart';
import 'widgets.dart';

/// تبويب «إنجازاتي»: كل الإنجازات مع شريط تقدم لكل منها.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'إنجازاتي 🏆',
      showBanner: false,
      body: ValueListenableBuilder<int>(
        valueListenable: Store.tick,
        builder: (context, _, __) {
          final done = Store.unlockedAchievements;
          final list = Achievements.all;
          // غير المكتملة أولاً (الأقرب إكمالاً في الأعلى) ثم المفتوحة
          double ratio(Achievement a) =>
              (a.progress() / a.target).clamp(0.0, 1.0).toDouble();
          final sorted = [...list]..sort((a, b) {
              final da = done.contains(a.id) ? 1 : 0;
              final db = done.contains(b.id) ? 1 : 0;
              if (da != db) return da - db == 1 ? 1 : -1;
              return ratio(b).compareTo(ratio(a));
            });
          final unlockedCount = list.where((a) => done.contains(a.id)).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Summary(unlocked: unlockedCount, total: list.length),
              const SizedBox(height: 14),
              for (final a in sorted)
                _AchievementCard(a: a, unlocked: done.contains(a.id)),
              const SizedBox(height: 8),
              const Text(
                'الإنجازات تقيس نشاطك داخل اللعبة، لا مستوى ذكائك.',
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

class _Summary extends StatelessWidget {
  final int unlocked;
  final int total;
  const _Summary({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
            colors: [kGold.withValues(alpha: 0.35), kGold.withValues(alpha: 0.12)]),
        border: Border.all(color: kGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text('$unlocked/$total',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('إنجاز مفتوح',
              style: TextStyle(fontSize: 15, color: Colors.white70)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: total == 0 ? 0 : unlocked / total,
              color: kGold,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              StatChip(
                  icon: Icons.star, text: '${Store.totalStars()} نجمة', color: kGold),
              StatChip(
                  icon: Icons.local_fire_department,
                  text: 'أفضل سلسلة ${Store.bestStreak} يوم',
                  color: Colors.deepOrangeAccent),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement a;
  final bool unlocked;
  const _AchievementCard({required this.a, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final p = a.progress();
    final shown = p > a.target ? a.target : p;
    final color = unlocked ? kGold : Colors.white38;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: unlocked ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: unlocked ? kGold.withValues(alpha: 0.6) : Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(unlocked ? a.icon : Icons.lock_outline,
                size: 28, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? Colors.white : Colors.white70)),
                const SizedBox(height: 2),
                Text(a.desc,
                    style: const TextStyle(fontSize: 13, color: Colors.white60)),
                const SizedBox(height: 8),
                if (unlocked)
                  Text('✓ مكتمل  •  \u200E+${a.reward} لمعة',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent))
                else
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: shown / a.target,
                            color: kGold,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$shown/${a.target}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
