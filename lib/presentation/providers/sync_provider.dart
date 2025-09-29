// lib/presentation/providers/sync_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/core/services/sync_manager.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';

/// Provider global pour le SyncManager
final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(); // C'est un singleton
});

/// Provider pour écouter l'état de la synchronisation
final syncStateProvider = ChangeNotifierProvider<SyncManager>((ref) {
  return ref.watch(syncManagerProvider);
});

/// Provider pour obtenir les informations de synchronisation
final syncInfoProvider = Provider<SyncInfo>((ref) {
  final syncManager = ref.watch(syncStateProvider);

  return SyncInfo(
    state: syncManager.state,
    pendingCount: syncManager.pendingItemsCount,
    lastSyncTime: syncManager.lastSyncTime,
    lastError: syncManager.lastError,
    isSyncing: syncManager.isSyncing,
  );
});

/// Provider pour déclencher une synchronisation manuelle
final manualSyncProvider = FutureProvider.autoDispose<SyncResult>((ref) async {
  final syncManager = ref.read(syncManagerProvider);

  // Initialiser si nécessaire
  if (!syncManager.isInitialized) {
    final readingRepo = ref.read(readingRepositoryProvider);
    await syncManager.initialize(readingRepository: readingRepo);
  }

  // Effectuer la synchronisation
  final result = await syncManager.syncNow();

  // Invalider les providers dépendants après la sync
  if (result.success) {
    ref.invalidate(readingsProvider);
    ref.invalidate(pendingSyncCountProvider);
    ref.invalidate(todayReadingCountProvider);
    ref.invalidate(totalReadingCountProvider);
  }

  return result;
});

/// Classe pour encapsuler les informations de synchronisation
class SyncInfo {
  final SyncState state;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final bool isSyncing;

  SyncInfo({
    required this.state,
    required this.pendingCount,
    this.lastSyncTime,
    this.lastError,
    required this.isSyncing,
  });

  bool get hasError => state == SyncState.error && lastError != null;
  bool get isOffline => state == SyncState.offline;
  bool get hasPendingItems => pendingCount > 0;

  String get statusText {
    switch (state) {
      case SyncState.idle:
        if (pendingCount > 0) {
          return '$pendingCount показаний в очереди';
        }
        return lastSyncTime != null
            ? 'Синхронизировано ${_formatTime(lastSyncTime!)}'
            : 'Все данные синхронизированы';

      case SyncState.syncing:
        return 'Синхронизация...';

      case SyncState.success:
        return 'Синхронизация завершена';

      case SyncState.error:
        return 'Ошибка синхронизации';

      case SyncState.offline:
        return pendingCount > 0
            ? 'Офлайн режим ($pendingCount в очереди)'
            : 'Офлайн режим';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'только что';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин. назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч. назад';
    } else {
      return '${time.day}.${time.month} в ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
