// lib/presentation/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/config/theme.dart';
import 'package:metrix/config/app_colors.dart';
import 'package:metrix/core/services/sync_manager.dart';
import 'package:metrix/core/utils/connectivity_helper.dart';
import 'package:metrix/presentation/providers/auth_provider.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isSyncing = false;
  String _statusMessage = 'Загрузка...';
  double _syncProgress = 0.0;
  int _pendingItems = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Attendre que l'animation du splash démarre
    await Future.delayed(const Duration(milliseconds: 500));

    // Vérifier l'authentification
    await _checkAuth();

    if (!mounted) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      // Pas connecté, aller au login
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Utilisateur connecté, synchroniser les données
    await _performInitialSync();

    if (!mounted) return;

    // Navigation vers l'écran principal
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _checkAuth() async {
    setState(() {
      _statusMessage = 'Проверка авторизации...';
    });

    // Attendre que l'état d'auth se charge
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return ref.read(authStateProvider).isLoading && mounted;
      });
    }
  }

  Future<void> _performInitialSync() async {
    // Vérifier s'il y a des données en attente
    final repository = ref.read(readingRepositoryProvider);
    _pendingItems = await repository.getPendingSyncCount();

    if (_pendingItems == 0) {
      setState(() {
        _statusMessage = 'Данные актуальны';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    // Vérifier la connexion
    final isOnline = await ConnectivityHelper.checkConnectivity();

    if (!isOnline) {
      setState(() {
        _statusMessage = 'Работа в офлайн режиме';
      });
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    // Effectuer la synchronisation
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Синхронизация $_pendingItems показаний...';
    });

    try {
      // Initialiser le SyncManager
      final syncManager = SyncManager();
      if (!syncManager.isInitialized) {
        await syncManager.initialize(readingRepository: repository);
      }

      // Écouter les changements pour mettre à jour l'UI
      syncManager.addListener(_onSyncStateChanged);

      // Effectuer la synchronisation
      final result = await syncManager.syncNow();

      if (result.success) {
        setState(() {
          _syncProgress = 1.0;
          _statusMessage = 'Синхронизировано ${result.itemsSynced} показаний';
        });
      } else if (result.errorMessage?.contains('connection') ?? false) {
        setState(() {
          _statusMessage = 'Продолжение в офлайн режиме';
        });
      } else {
        setState(() {
          _statusMessage =
              'Синхронизировано ${result.itemsSynced} из $_pendingItems';
        });
      }

      syncManager.removeListener(_onSyncStateChanged);

      // Attendre un peu pour que l'utilisateur voie le message
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Sync error during splash: $e');
      setState(() {
        _statusMessage = 'Продолжение без синхронизации';
      });
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _onSyncStateChanged() {
    final syncManager = SyncManager();
    if (syncManager.state == SyncState.syncing) {
      setState(() {
        _syncProgress = 0.5; // Animation de progression
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo avec indicateur de sync
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle de progression si sync en cours
                    if (_isSyncing)
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _syncProgress > 0 ? _syncProgress : null,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),

                    // Logo principal
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: MeterSyncTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isSyncing
                            ? const Icon(
                                Icons.sync,
                                key: ValueKey('sync'),
                                size: 60,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.speed,
                                key: ValueKey('speed'),
                                size: 60,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'СЧЕТ-УЧЕТ',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Message de statut
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusMessage,
                    key: ValueKey(_statusMessage),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Afficher le nombre d'items en attente si pertinent
                if (_pendingItems > 0 && !_isSyncing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_pendingItems показаний в очереди',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
