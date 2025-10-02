import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/core/services/sync_manager.dart';
import 'package:metrix/core/services/update_checker.dart';
import 'package:metrix/core/theme.dart';
import 'package:metrix/main.dart';
import 'package:metrix/presentation/providers/auth_provider.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';
import 'package:metrix/presentation/screens/splash_screen.dart';
import 'package:metrix/routes/app_router.dart';

class MeterSyncApp extends ConsumerStatefulWidget {
  const MeterSyncApp({super.key});

  @override
  ConsumerState<MeterSyncApp> createState() => _MeterSyncAppState();
}

class _MeterSyncAppState extends ConsumerState<MeterSyncApp>
    with WidgetsBindingObserver {
  final UpdateChecker _updateChecker = UpdateChecker();
  final SyncManager _syncManager = SyncManager();
  bool _isSyncManagerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Démarrer les vérifications périodiques de mise à jour
    _updateChecker.startPeriodicCheck();

    // Initialiser le SyncManager après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSyncManager();
      _checkForUpdateWithContext();
    });
  }

  Future<void> _initializeSyncManager() async {
    // Attendre que l'authentification soit chargée
    await Future.delayed(const Duration(seconds: 1));

    final user = ref.read(authStateProvider).value;
    if (user != null) {
      // L'utilisateur est connecté, initialiser le SyncManager
      final readingRepo = ref.read(readingRepositoryProvider);
      // final meterRepo = ref.read(meterRepositoryProvider); // Si vous avez un provider pour MeterRepository

      await _syncManager.initialize(
        readingRepository: readingRepo,
        // meterRepository: meterRepo,
      );

      // Démarrer la synchronisation automatique
      _syncManager.startAutoSync();
      _isSyncManagerInitialized = true;

      debugPrint('App: SyncManager initialized and auto-sync started');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateChecker.dispose();
    if (_isSyncManagerInitialized) {
      _syncManager.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');

        // Vérifier les mises à jour
        _checkForUpdateWithContext();

        // Synchroniser si nécessaire quand l'app revient au premier plan
        if (_isSyncManagerInitialized) {
          debugPrint('App resumed - triggering sync check');
          _syncManager.syncIfNeeded();
        } else {
          // Réessayer l'initialisation si elle n'a pas été faite
          _initializeSyncManager();
        }
        break;

      case AppLifecycleState.paused:
        debugPrint('App paused');
        // Possibilité de forcer une sync avant la mise en pause
        if (_isSyncManagerInitialized && _syncManager.pendingItemsCount > 0) {
          debugPrint(
            'App pausing with ${_syncManager.pendingItemsCount} pending items',
          );
          _syncManager.syncNow();
        }
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Rien de spécial à faire
        break;
    }
  }

  Future<void> _checkForUpdateWithContext() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null) {
        await _updateChecker.checkForUpdate(context: navigatorContext);
      }
    }
  }

  void _setSystemUI(BuildContext context) {
    final theme = Theme.of(context);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUI(context);
    // Écouter les changements d'authentification pour gérer le SyncManager
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.value == null && next.value != null) {
        // L'utilisateur vient de se connecter
        debugPrint('User logged in, initializing SyncManager');
        _initializeSyncManager();
      } else if (previous?.value != null && next.value == null) {
        // L'utilisateur s'est déconnecté
        debugPrint('User logged out, stopping SyncManager');
        if (_isSyncManagerInitialized) {
          _syncManager.stopAutoSync();
          _isSyncManagerInitialized = false;
        }
      }
    });

    return MaterialApp(
      title: 'Metrix',
      theme: MeterSyncTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
