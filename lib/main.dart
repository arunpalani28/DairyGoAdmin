import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_login_shell.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const DairyGoAdminApp());
}

class DairyGoAdminApp extends StatelessWidget {
  const DairyGoAdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Aavinam Admin',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
      scaffoldBackgroundColor: const Color(0xFFEEF3FA),
    ),
    home: const SplashScreen(),
  );
}
