import 'package:flutter/material.dart';

import 'questions.dart';
import 'stages.dart';
import 'store.dart';
import 'widgets.dart';

/// خريطة المراحل: سهل ← متوسط ← صعب
class StageMapScreen extends StatelessWidget {
  final Track track;
  const StageMapScreen({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: track.title,
      body: ValueListenableBuilder<int>(
        valueListenable: Store.tick,
        builder: (context, _, __) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final tier in Tier.values) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 26,
                        decoration: BoxDecoration(
                            color: tier.color,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(width: 10),
                    Text('المستوى ${tier.label}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < track.stagesPerTier; i++)
                    _StageTile(ref: StageRef(track, tier, i)),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final StageRef ref;
  const _StageTile({required this.ref});

  @override
  Widget build(BuildContext context) {
    final unlocked = isUnlocked(ref);
    final stars = Store.stars(ref.key);
    final color = ref.tier.color;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (!unlocked) {
          showSnack(context, 'أنهِ المرحلة السابقة أولاً (نجمة واحدة على الأقل)');
          return;
        }
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => screenFor(ref)));
      },
      child: Container(
        width: 96,
        height: 104,
        decoration: BoxDecoration(
          color: unlocked
              ? color.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: unlocked ? color : Colors.white24, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unlocked)
              Text('${ref.index + 1}',
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold))
            else
              const Icon(Icons.lock, size: 30, color: Colors.white38),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var s = 0; s < 3; s++)
                  Icon(s < stars ? Icons.star : Icons.star_border,
                      size: 16, color: kGold),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
