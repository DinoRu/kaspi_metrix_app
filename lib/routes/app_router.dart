import 'package:flutter/material.dart';
import 'package:metrix/data/models/reading.dart';
import 'package:metrix/presentation/screens/reading_detail_screen.dart';
import 'package:metrix/presentation/screens/splash_screen.dart';
import 'package:metrix/presentation/screens/login_screen.dart';
import 'package:metrix/presentation/screens/home_screen.dart';
import 'package:metrix/presentation/screens/reading_form_screen.dart';
import 'package:metrix/data/models/meter.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/reading/new':
        final meter = settings.arguments as Meter?;
        return MaterialPageRoute(
          builder: (_) => ReadingFormScreen(meter: meter),
        );

      case '/reading/detail':
        final reading = settings.arguments as Reading;
        return MaterialPageRoute(
          builder: (_) => ReadingDetailScreen(reading: reading),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
