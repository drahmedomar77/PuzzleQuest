import 'package:flutter/material.dart';

import 'ads.dart';
import 'store.dart';

const Color kBgTop = Color(0xFF1B1464);
const Color kBgBottom = Color(0xFF0B0A2A);
const Color kGold = Color(0xFFFFB300);

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center)));
}

/// هيكل الشاشة بخلفية متدرجة وبانر إعلاني أسفلها
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBanner;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgTop, kBgBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: actions,
        ),
        body: SafeArea(child: body),
        bottomNavigationBar:
            showBanner ? const SafeArea(child: BannerAdWidget()) : null,
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const StatChip(
      {super.key, required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// شاشة نتيجة المرحلة (مشتركة بين الألغاز والنطق)
class StageResult extends StatefulWidget {
  final int stars;
  final int coins;
  final String summary;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final VoidCallback onExit;

  const StageResult({
    super.key,
    required this.stars,
    required this.coins,
    required this.summary,
    required this.onRetry,
    required this.onNext,
    required this.onExit,
  });

  @override
  State<StageResult> createState() => _StageResultState();
}

class _StageResultState extends State<StageResult> {
  bool _doubled = false;

  @override
  Widget build(BuildContext context) {
    final passed = widget.stars > 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(passed ? 'أحسنت! 🎉' : 'حاول مرة أخرى 💪',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(i < widget.stars ? Icons.star : Icons.star_border,
                      size: 54, color: kGold),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.summary, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            StatChip(
                icon: Icons.bolt,
                text: '+${widget.coins} لمعة${_doubled ? ' (×2)' : ''}',
                color: kGold),
            const SizedBox(height: 16),
            if (!_doubled && widget.coins > 0)
              OutlinedButton.icon(
                onPressed: () {
                  Ads.showRewarded(
                    onReward: () async {
                      await Store.addCoins(widget.coins);
                      if (mounted) setState(() => _doubled = true);
                    },
                    onUnavailable: () =>
                        showSnack(context, 'لا يوجد إعلان متاح الآن، جرّب لاحقاً'),
                  );
                },
                icon: const Icon(Icons.ondemand_video),
                label: const Text('ضاعف الجائزة بمشاهدة إعلان'),
              ),
            const SizedBox(height: 16),
            if (widget.onNext != null && passed)
              FilledButton(
                onPressed: widget.onNext,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text('المرحلة التالية', style: TextStyle(fontSize: 18)),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(onPressed: widget.onRetry, child: const Text('إعادة المرحلة')),
            TextButton(onPressed: widget.onExit, child: const Text('رجوع للمراحل')),
          ],
        ),
      ),
    );
  }
}
