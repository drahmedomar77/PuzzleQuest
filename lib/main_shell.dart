import 'package:flutter/material.dart';

import 'achievements.dart';
import 'achievements_screen.dart';
import 'ads.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'store.dart';
import 'widgets.dart';

/// الهيكل الرئيسي: ثلاثة تبويبات (الرئيسية، إنجازاتي، الإعدادات) وشريط تنقل سفلي،
/// مع بانر إعلاني واحد فوق الشريط بدل بانر لكل تبويب.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Store.tick.addListener(Achievements.check);
    // فحص أولي يمنح الإنجازات المستحقة لمن لعب قبل هذا التحديث
    WidgetsBinding.instance.addPostFrameCallback((_) => Achievements.check());
  }

  @override
  void dispose() {
    Store.tick.removeListener(Achievements.check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBottom,
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          AchievementsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            backgroundColor: kBgBottom,
            indicatorColor: kGold.withValues(alpha: 0.25),
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'الرئيسية'),
              NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: 'إنجازاتي'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'الإعدادات'),
            ],
          ),
        ],
      ),
    );
  }
}
