import 'package:flutter/material.dart';

import 'questions.dart';
import 'widgets.dart';

/// لوحة الأسئلة المرئية: معادلات الرموز ومربعات الأرقام.
/// تُعرض دائماً من اليسار لليمين لأن الرموز والأرقام لا تتبع اتجاه العربية.
class QuestionVisual extends StatelessWidget {
  final QKind kind;
  final List<String> items;
  const QuestionVisual({super.key, required this.kind, required this.items});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: kind == QKind.tiles ? _tiles() : _equations(),
      ),
    );
  }

  Widget _tiles() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          _tile(items[i], items[i] == '?'),
      ],
    );
  }

  Widget _tile(String s, bool unknown) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: unknown ? kGold : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: unknown ? kGold : Colors.white24, width: 1.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(s,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: unknown ? Colors.black : Colors.white)),
        ),
      ),
    );
  }

  Widget _equations() {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _row(items[i], i == items.length - 1),
          ),
      ],
    );
  }

  Widget _row(String line, bool last) {
    final tokens = line.split(' ').where((e) => e.isNotEmpty).toList();
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tk in tokens)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(tk,
                style: TextStyle(
                    fontSize: _isSymbol(tk) ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: last && !_isSymbol(tk) && _isPlain(tk)
                        ? kGold
                        : Colors.white)),
          ),
      ],
    );
    final boxed = FittedBox(fit: BoxFit.scaleDown, child: row);
    if (!last) return boxed;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: kGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGold.withValues(alpha: 0.7)),
      ),
      child: boxed,
    );
  }

  static bool _isSymbol(String s) => const {'+', '-', '×', '÷', '='}.contains(s);
  static bool _isPlain(String s) => s == '?';
}

/// شبكة خيارات من الإيموجي (سؤال الشاذ).
class EmojiOptions extends StatelessWidget {
  final List<String> options;
  final Color Function(int) colorOf;
  final bool Function(int) hiddenOf;
  final void Function(int)? onPick;
  const EmojiOptions({
    super.key,
    required this.options,
    required this.colorOf,
    required this.hiddenOf,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var k = 0; k < options.length; k++)
          Opacity(
            opacity: hiddenOf(k) ? 0.15 : 1,
            child: Material(
              color: colorOf(k),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: hiddenOf(k) || onPick == null ? null : () => onPick!(k),
                child: SizedBox(
                  width: 96,
                  height: 84,
                  child: Center(
                    child: Text(options[k],
                        style: const TextStyle(fontSize: 38)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
