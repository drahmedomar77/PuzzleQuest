import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'quick_logic.dart';
import 'store.dart';
import 'widgets.dart';

/// تبويب «الإعدادات»: الصوت، مشاركة التطبيق، عن التطبيق، وإعادة ضبط التقدم.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _share(BuildContext context) async {
    final text = StringBuffer(
        'جرّب $kBrand: ألغاز ذكاء وتحدي نطق واختبار خاطف مع بطاقة نتيجة تشاركها مع أصدقائك ✨');
    if (kShareLink.isNotEmpty) text.write('\n$kShareLink');
    try {
      await Share.share(text.toString());
    } catch (_) {
      if (context.mounted) showSnack(context, 'تعذّرت المشاركة، حاول مرة أخرى');
    }
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إعادة ضبط التقدم؟'),
        content: const Text(
            'سيُمسح كل شيء: النجوم واللمعات والإنجازات وأفضل نتيجة. لا يمكن التراجع عن ذلك.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('مسح كل شيء')),
        ],
      ),
    );
    if (ok != true) return;
    await Store.resetAll();
    if (context.mounted) showSnack(context, 'تمت إعادة الضبط');
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('عن $kBrand'),
        content: const Text(
            'لمعة تطبيق للتسلية والتدريب الذهني.\n\n'
            'مؤشر لمعة ليس مقياساً سريرياً لمعدل الذكاء، ولا نعرض نسباً أو ترتيباً مقارنة بالآخرين.\n\n'
            'يعرض التطبيق إعلانات، ويستخدم الميكروفون في تحدي النطق فقط، ولا يرسل بياناتك الشخصية إلى خوادمنا.\n\n'
            'تُحفظ نتائجك على جهازك فقط.',
            style: TextStyle(height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('حسناً')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الإعدادات',
      showBanner: false,
      body: ValueListenableBuilder<int>(
        valueListenable: Store.tick,
        builder: (context, _, __) => ListView(
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
                    icon: Icons.star,
                    text: '${Store.totalStars()} نجمة',
                    color: Colors.amber),
                StatChip(
                    icon: Icons.local_fire_department,
                    text: '${Store.streak} يوم متتالي',
                    color: Colors.deepOrangeAccent),
              ],
            ),
            const SizedBox(height: 18),
            _Tile(
              child: SwitchListTile(
                secondary: Icon(
                    Store.soundOn ? Icons.volume_up : Icons.volume_off),
                title: const Text('المؤثرات الصوتية'),
                subtitle: const Text('أصوات الإجابة الصحيحة والخاطئة'),
                value: Store.soundOn,
                onChanged: (v) => Store.setSound(v),
              ),
            ),
            _Tile(
              child: ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('شارك التطبيق مع أصدقائك'),
                onTap: () => _share(context),
              ),
            ),
            _Tile(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('عن التطبيق والخصوصية'),
                onTap: () => _about(context),
              ),
            ),
            _Tile(
              child: ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('إعادة ضبط التقدم',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => _reset(context),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'للتسلية والتدريب وليس اختباراً طبياً للذكاء.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget child;
  const _Tile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
