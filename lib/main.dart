import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'services/hive_service.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await HiveService.init();
  final bool isLoggedIn = await SessionService.isLoggedIn();
  FlutterNativeSplash.remove();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dutch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFE742A),
          primary: const Color(0xFFFE742A),
        ),
        primaryColor: const Color(0xFFFE742A),
        scaffoldBackgroundColor: const Color(0xFFECECEC),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
