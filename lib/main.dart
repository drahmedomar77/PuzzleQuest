import 'package:flutter/material.dart';

import 'achievements.dart';
import 'ads.dart';
import 'main_shell.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  Ads.init(); // لا ننتظره حتى لا نؤخر فتح التطبيق
  runApp(const LamaaApp());
}

class LamaaApp extends StatelessWidget {
  const LamaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لمعة',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.dark,
        ),
      ),
      // واجهة من اليمين إلى اليسار
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const MainShell(),
    );
  }
}
