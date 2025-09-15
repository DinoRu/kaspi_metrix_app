import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/data/models/reading.dart';
import 'package:metrix/data/repositories/reading_repository.dart';
import 'package:metrix/presentation/providers/auth_provider.dart';

final readingRepositoryProvider = Provider((ref) {
  return ReadingRepository(ref.watch(apiClientProvider));
});

final readingsProvider = FutureProvider.family<List<Reading>, String?>((
  ref,
  meterId,
) async {
  final repository = ref.watch(readingRepositoryProvider);
  return repository.getReadings(meterId: meterId);
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(readingRepositoryProvider);
  return repository.getPendingSyncCount();
});

final todayReadingCountProvider = FutureProvider<int>((ref) {
  return ref.read(readingRepositoryProvider).getTodayReadingsCount();
});

final totalReadingCountProvider = FutureProvider<int>((ref) {
  return ref.read(readingRepositoryProvider).getTotalReadingsCount();
});

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
      return SyncStatusNotifier(ref.watch(readingRepositoryProvider));
    });

enum SyncStatus { idle, syncing, success, error }

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final ReadingRepository _repository;

  SyncStatusNotifier(this._repository) : super(SyncStatus.idle);

  Future<void> syncNow() async {
    state = SyncStatus.syncing;
    try {
      await _repository.syncReadings();
      state = SyncStatus.success;

      // Reset to idle after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = SyncStatus.idle;
        }
      });
    } catch (e) {
      state = SyncStatus.error;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = SyncStatus.idle;
        }
      });
      rethrow;
    }
  }
}
