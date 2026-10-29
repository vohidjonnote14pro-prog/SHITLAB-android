import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF141922),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  app.init();
  runApp(const ShitLabApp());
}

class ShitLabApp extends StatelessWidget {
  const ShitLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShitLab',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}
