// lib/core/services/sync_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metrix/core/sync/outbox_manager.dart';
import 'package:metrix/core/utils/connectivity_helper.dart';
import 'package:metrix/data/repositories/reading_repository.dart';
import 'package:metrix/data/repositories/meter_repository.dart';

enum SyncState { idle, syncing, success, error, offline }

class SyncResult {
  final bool success;
  final int itemsSynced;
  final int itemsFailed;
  final String? errorMessage;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.itemsSynced,
    this.itemsFailed = 0,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SyncManager extends ChangeNotifier {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final OutboxManager _outboxManager = OutboxManager();
  ReadingRepository? _readingRepository;
  MeterRepository? _meterRepository;

  Timer? _periodicSyncTimer;
  Timer? _retryTimer;
  StreamSubscription<bool>? _connectivitySubscription;

  SyncState _state = SyncState.idle;
  DateTime? _lastSyncTime;
  int _pendingItemsCount = 0;
  String? _lastError;
  bool _isInitialized = false;

  // Configuration
  static const Duration _syncInterval = Duration(
    minutes: 15,
  ); // Sync toutes les 15 minutes
  static const Duration _retryDelay = Duration(
    seconds: 30,
  ); // Réessayer après 30 secondes en cas d'échec
  static const Duration _offlineCheckInterval = Duration(
    seconds: 10,
  ); // Vérifier la connexion toutes les 10 secondes si offline

  // Getters
  SyncState get state => _state;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingItemsCount => _pendingItemsCount;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _state == SyncState.syncing;

  /// Initialize avec les repositories
  Future<void> initialize({
    required ReadingRepository readingRepository,
    MeterRepository? meterRepository,
  }) async {
    if (_isInitialized) {
      debugPrint('SyncManager: Already initialized');
      return;
    }

    _readingRepository = readingRepository;
    _meterRepository = meterRepository;

    // Écouter les changements de connectivité
    _connectivitySubscription = ConnectivityHelper.connectivityStream.listen(
      _onConnectivityChanged,
    );

    // Compter les items en attente
    await _updatePendingCount();

    _isInitialized = true;
    debugPrint(
      'SyncManager: Initialized with $_pendingItemsCount pending items',
    );
  }

  /// Démarre la synchronisation automatique
  void startAutoSync() {
    if (!_isInitialized) {
      debugPrint('SyncManager: Cannot start auto-sync, not initialized');
      return;
    }

    stopAutoSync(); // Arrêter tout timer existant

    _periodicSyncTimer = Timer.periodic(_syncInterval, (_) {
      debugPrint('SyncManager: Periodic sync triggered');
      syncIfNeeded();
    });

    debugPrint('SyncManager: Auto-sync started (interval: $_syncInterval)');
  }

  /// Arrête la synchronisation automatique
  void stopAutoSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    debugPrint('SyncManager: Auto-sync stopped');
  }

  /// Synchronise uniquement s'il y a des éléments en attente et une connexion
  Future<SyncResult> syncIfNeeded({bool force = false}) async {
    // Vérifier les conditions
    if (!force) {
      if (_state == SyncState.syncing) {
        debugPrint('SyncManager: Already syncing, skipping');
        return SyncResult(
          success: false,
          itemsSynced: 0,
          errorMessage: 'Already syncing',
        );
      }

      await _updatePendingCount();
      if (_pendingItemsCount == 0) {
        debugPrint('SyncManager: No pending items, skipping sync');
        _updateState(SyncState.idle);
        return SyncResult(success: true, itemsSynced: 0);
      }

      if (!await ConnectivityHelper.checkConnectivity()) {
        debugPrint('SyncManager: No connection, skipping sync');
        _updateState(SyncState.offline);
        _scheduleRetryWhenOnline();
        return SyncResult(
          success: false,
          itemsSynced: 0,
          errorMessage: 'No connection',
        );
      }
    }

    return await syncNow();
  }

  /// Force la synchronisation maintenant
  Future<SyncResult> syncNow() async {
    if (!_isInitialized) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        errorMessage: 'SyncManager not initialized',
      );
    }

    debugPrint('SyncManager: Starting sync...');
    _updateState(SyncState.syncing);
    _lastError = null;

    int itemsSynced = 0;
    int itemsFailed = 0;
    String? errorMessage;

    try {
      // Vérifier la connexion
      if (!await ConnectivityHelper.checkConnectivity()) {
        throw Exception('No internet connection');
      }

      // Synchroniser les lectures
      if (_readingRepository != null) {
        debugPrint('SyncManager: Syncing readings...');
        final pendingBefore = await _readingRepository!.getPendingSyncCount();

        await _readingRepository!.syncReadings();

        final pendingAfter = await _readingRepository!.getPendingSyncCount();
        itemsSynced += (pendingBefore - pendingAfter);
      }

      // Synchroniser les compteurs (si nécessaire)
      if (_meterRepository != null) {
        debugPrint('SyncManager: Syncing meters...');
        // await _meterRepository!.syncMeters(); // À implémenter si nécessaire
      }

      // Mettre à jour le compte des items en attente
      await _updatePendingCount();

      if (_pendingItemsCount == 0) {
        _updateState(SyncState.success);
        _lastSyncTime = DateTime.now();
        debugPrint(
          'SyncManager: Sync completed successfully. $itemsSynced items synced',
        );
      } else {
        // Il reste des items, probablement à cause d'erreurs
        _updateState(SyncState.error);
        errorMessage = 'Some items failed to sync';
        itemsFailed = _pendingItemsCount;
        debugPrint(
          'SyncManager: Sync partially completed. $itemsSynced synced, $itemsFailed failed',
        );
        _scheduleRetry();
      }
    } catch (e) {
      debugPrint('SyncManager: Sync error: $e');
      _lastError = e.toString();
      errorMessage = e.toString();
      _updateState(SyncState.error);

      if (e.toString().contains('connection') ||
          e.toString().contains('internet')) {
        _updateState(SyncState.offline);
        _scheduleRetryWhenOnline();
      } else {
        _scheduleRetry();
      }
    }

    // Reset to idle after a short delay
    if (_state == SyncState.success) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_state == SyncState.success) {
          _updateState(SyncState.idle);
        }
      });
    }

    return SyncResult(
      success: _state == SyncState.success,
      itemsSynced: itemsSynced,
      itemsFailed: itemsFailed,
      errorMessage: errorMessage,
    );
  }

  /// Met à jour le nombre d'items en attente
  Future<void> _updatePendingCount() async {
    if (_readingRepository != null) {
      _pendingItemsCount = await _readingRepository!.getPendingSyncCount();
      notifyListeners();
    }
  }

  /// Met à jour l'état et notifie les listeners
  void _updateState(SyncState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Gère les changements de connectivité
  void _onConnectivityChanged(bool isOnline) {
    debugPrint('SyncManager: Connectivity changed - online: $isOnline');

    if (isOnline && _state == SyncState.offline) {
      debugPrint('SyncManager: Back online, triggering sync');
      // Retour en ligne, synchroniser immédiatement
      Future.delayed(const Duration(seconds: 2), () {
        syncIfNeeded();
      });
    } else if (!isOnline) {
      _updateState(SyncState.offline);
      _scheduleRetryWhenOnline();
    }
  }

  /// Planifie un réessai après un délai
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      debugPrint('SyncManager: Retry triggered');
      syncIfNeeded();
    });
  }

  /// Planifie un réessai quand la connexion reviendra
  void _scheduleRetryWhenOnline() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_offlineCheckInterval, (_) async {
      if (await ConnectivityHelper.checkConnectivity()) {
        _retryTimer?.cancel();
        debugPrint('SyncManager: Connection restored, syncing...');
        syncIfNeeded();
      }
    });
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    stopAutoSync();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
