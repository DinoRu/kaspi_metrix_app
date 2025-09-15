import 'package:flutter/material.dart';
import 'package:metrix/core/theme.dart';
import 'package:metrix/main.dart';
import 'package:metrix/presentation/screens/splash_screen.dart';
import 'package:metrix/routes/app_router.dart';

class MeterSyncApp extends StatelessWidget {
  const MeterSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metrix',
      theme: MeterSyncTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
