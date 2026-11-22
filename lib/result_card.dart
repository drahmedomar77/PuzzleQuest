import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'quick_logic.dart';

const Color _gold = Color(0xFFFFD166);
const Color _lavender = Color(0xFFB8B8E0);

/// بطاقة النتيجة (تصميم 1080×1350، نسبة 4:5 مناسبة لإنستغرام وواتساب).
/// تُعرض داخل التطبيق بنفس الرسّام الذي يُنتج الصورة المشاركة، فما تراه هو ما يصل للأصدقاء.
class ResultCardPainter extends CustomPainter {
  final QuickResult result;
  const ResultCardPainter(this.result);

  static const double w = 1080;
  static const double h = 1350;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / w, size.height / h);
    _draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ResultCardPainter old) => old.result != result;

  void _draw(Canvas c) {
    const cx = w / 2;

    // الخلفية والإطار
    c.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(0, h),
          const [Color(0xFF2A2A7A), Color(0xFF0A0A2A)],
        ),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(30, 30, w - 30, h - 30), const Radius.circular(48)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = _gold.withValues(alpha: 0.47),
    );

    // العلامة
    _star(c, cx, 85, 30);
    _text(c, kBrand, cx, 175, 64, _gold, bold: true, maxWidth: 600);
    _text(c, 'مؤشر $kBrand', cx, 225, 36, _lavender, maxWidth: 800);

    // الرقم واللقب
    _text(c, '${result.index}', cx, 395, 190, Colors.white,
        bold: true, maxWidth: 500);
    _text(c, 'من 100', cx, 440, 34, _lavender, maxWidth: 500);
    _text(c, result.band, cx, 515, 68, _gold, bold: true, maxWidth: 900);

    _radar(c, cx, 890, 225);

    // نقطة القوة والتحدي
    final s = result.strongest;
    _text(
      c,
      s == null ? 'تدرّب أكثر لتظهر نقاط قوتك' : 'نقطة قوتك: ${kAxisLabels[s]}',
      cx, 1224, 38, Colors.white,
    );
    _text(c, 'هل تستطيع هزيمتي؟', cx, 1272, 42, _gold, bold: true);
    _text(c, 'للتسلية والتدريب وليس اختباراً طبياً للذكاء', cx, 1306, 24,
        _lavender);
  }

  void _radar(Canvas c, double cx, double cy, double r) {
    final n = kAxisLabels.length;
    Offset point(int i, double radius) {
      final a = -pi / 2 + 2 * pi * i / n;
      return Offset(cx + radius * cos(a), cy + radius * sin(a));
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _lavender.withValues(alpha: 0.35);

    // الحلقات الشبكية
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = point(i, r * ring / 4);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      c.drawPath(path, grid);
    }
    // المحاور
    for (var i = 0; i < n; i++) {
      c.drawLine(Offset(cx, cy), point(i, r), grid);
    }

    // مضلع القيم (حد أدنى صغير حتى لا ينهار الشكل عند الصفر)
    final data = Path();
    final dots = <Offset>[];
    for (var i = 0; i < n; i++) {
      final frac = max((result.axes[i] ?? 0) / 100, 0.04);
      final p = point(i, r * frac);
      dots.add(p);
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    c.drawPath(
        data, Paint()..color = _gold.withValues(alpha: 0.37));
    c.drawPath(
      data,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = _gold,
    );
    for (final p in dots) {
      c.drawCircle(p, 10, Paint()..color = _gold);
    }

    // أسماء المحاور وقيمها
    for (var i = 0; i < n; i++) {
      final p = point(i, r + 66);
      final v = result.axes[i];
      _text(c, kAxisLabels[i], p.dx, p.dy - 4, 34, Colors.white,
          bold: true, maxWidth: 230);
      _text(c, v == null ? '—' : '$v', p.dx, p.dy + 34, 30, _gold,
          maxWidth: 230);
    }
  }

  /// نجمة رباعية صغيرة فوق اسم العلامة.
  void _star(Canvas c, double x, double y, double s) {
    final k = s * 0.28;
    final path = Path()
      ..moveTo(x, y - s)
      ..lineTo(x + k, y - k)
      ..lineTo(x + s, y)
      ..lineTo(x + k, y + k)
      ..lineTo(x, y + s)
      ..lineTo(x - k, y + k)
      ..lineTo(x - s, y)
      ..lineTo(x - k, y - k)
      ..close();
    c.drawPath(path, Paint()..color = _gold);
  }

  /// نص متوسَّط أفقياً على خط أساس محدد، يصغّر نفسه إذا تجاوز العرض المسموح.
  void _text(
    Canvas c,
    String s,
    double cx,
    double baseline,
    double size,
    Color color, {
    bool bold = false,
    double maxWidth = 900,
  }) {
    TextPainter make(double fs) => TextPainter(
          text: TextSpan(
            text: s,
            style: TextStyle(
              fontSize: fs,
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();

    var tp = make(size);
    if (tp.width > maxWidth) tp = make(size * maxWidth / tp.width);
    final dy = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(c, Offset(cx - tp.width / 2, baseline - dy));
  }
}

/// يرسم البطاقة كصورة PNG بحجم 1080×1350.
Future<Uint8List> renderResultCardPng(QuickResult result) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  ResultCardPainter(result)
      .paint(canvas, const Size(ResultCardPainter.w, ResultCardPainter.h));
  final image = await recorder
      .endRecording()
      .toImage(ResultCardPainter.w.toInt(), ResultCardPainter.h.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// يحفظ البطاقة مؤقتاً ويفتح قائمة المشاركة (واتساب، إنستغرام، ...).
Future<void> shareResultCard(QuickResult result, String text) async {
  final bytes = await renderResultCardPng(result);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/lumaa_result.png');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png')],
    text: text,
  );
}
