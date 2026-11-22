import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'store.dart';

/// مؤثرات صوتية قصيرة (الملفات في assets/sounds). تحترم زر الكتم في الشاشة الرئيسية.
/// وضع lowLatency يستخدم SoundPool في أندرويد فلا يقاطع موسيقى المستخدم ولا يتأخر.
class Sfx {
  static final Map<String, AudioPlayer> _players = {};

  static Future<void> _play(String file) async {
    if (!Store.soundOn) return;
    try {
      var p = _players[file];
      if (p == null) {
        p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _players[file] = p;
      }
      await p.stop();
      await p.play(AssetSource('sounds/$file'), volume: 0.9);
    } catch (_) {
      // الصوت ميزة إضافية: أي خطأ فيه يجب ألا يعطّل اللعبة
    }
  }

  static void correct() => unawaited(_play('correct.wav'));
  static void wrong() => unawaited(_play('wrong.wav'));
  static void finish() => unawaited(_play('finish.wav'));
}
