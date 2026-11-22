import 'package:flutter/material.dart';

import 'questions.dart';
import 'quiz_screen.dart';
import 'speech_screen.dart';
import 'store.dart';

enum Track { iq, speech }

extension TrackX on Track {
  String get title => this == Track.iq ? 'ألغاز الذكاء' : 'تحدي النطق';
  int get stagesPerTier => this == Track.iq ? 3 : 2;
}

class StageRef {
  final Track track;
  final Tier tier;
  final int index;
  const StageRef(this.track, this.tier, this.index);

  String get key => '${track.name}_${tier.name}_$index';
}

List<StageRef> allStages(Track t) => [
      for (final tier in Tier.values)
        for (var i = 0; i < t.stagesPerTier; i++) StageRef(t, tier, i),
    ];

bool isUnlocked(StageRef s) {
  final all = allStages(s.track);
  final pos = all.indexWhere((e) => e.key == s.key);
  if (pos <= 0) return true;
  return Store.stars(all[pos - 1].key) >= 1;
}

StageRef? nextStage(StageRef s) {
  final all = allStages(s.track);
  final pos = all.indexWhere((e) => e.key == s.key);
  if (pos < 0 || pos + 1 >= all.length) return null;
  return all[pos + 1];
}

Widget screenFor(StageRef s) =>
    s.track == Track.iq ? QuizScreen(stage: s) : SpeechScreen(stage: s);

void replaceWith(BuildContext context, StageRef s) {
  Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => screenFor(s)));
}
