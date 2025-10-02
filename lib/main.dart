import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:metrix/app.dart';
import 'package:metrix/core/database/database_helper.dart';
import 'package:metrix/core/services/update_checker.dart';
import 'package:metrix/core/utils/connectivity_helper.dart';
import 'package:metrix/core/utils/update_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void setSystemUIOverlayStyle(Brightness brightness, Color navBarColor) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // status bar transparente
      statusBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: navBarColor, // couleur de la barre navigation
      systemNavigationBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru', null);

  // await dotenv.load(fileName: ".env");

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize connectivity helper
  ConnectivityHelper.initialize();

  // Initialiser flutter_downloader
  await UpdateService.initialize();

  // Initilize update service
  await UpdateChecker().initialize();

  // Set system UI
  SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarColor: Colors.white,
  );

  runApp(const ProviderScope(child: MeterSyncApp()));
}
