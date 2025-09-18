// =====================================
// lib/presentation/providers/meter_provider.dart
// =====================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/data/models/meter.dart';
import 'package:metrix/data/repositories/meter_repository.dart';
import 'package:metrix/presentation/providers/auth_provider.dart';

/// Taille d'une page lue depuis la DB locale.
const _pageSize = 50;

final meterRepositoryProvider = Provider((ref) {
  return MeterRepository(ref.watch(apiClientProvider));
});

/// Texte de recherche tapé par l'utilisateur.
final meterSearchProvider = StateProvider<String>((ref) => '');

/// Provider pour forcer le refresh - increment this to trigger refresh
final meterRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Retourne le nombre de meters
final meterCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(meterRepositoryProvider);
  return repository.countLocal();
});

final localMetersProvider = FutureProvider<List<Meter>>((ref) {
  return ref.read(meterRepositoryProvider).getAllLocalMeters();
});

/// Provider cache-first (au 1er démarrage par ex.)
final allMetersCacheFirstProvider = FutureProvider<List<Meter>>((ref) async {
  final repo = ref.watch(meterRepositoryProvider);
  return repo.getAllMeters();
});

/// Provider principal : expose la liste cumulée paginée (offline-first).
final metersPagerProvider =
    AsyncNotifierProvider.autoDispose<MetersPager, List<Meter>>(
      () => MetersPager(),
    );

/// Optionnel : expose juste le flag hasMore (pratique pour l'UI).
final metersHasMoreProvider = Provider<bool>((ref) {
  return ref.read(metersPagerProvider.notifier).hasMore;
});

class MetersPager extends AutoDisposeAsyncNotifier<List<Meter>> {
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  MeterRepository get _repo => ref.read(meterRepositoryProvider);
  String get _q => ref.read(meterSearchProvider);

  @override
  Future<List<Meter>> build() async {
    _offset = 0;
    _hasMore = true;
    final localCount = await _repo.countLocal();
    if (localCount > 0) {
      return await _loadPage();
    }
    await _repo.syncAll(pageSize: 500);
    return await _loadPage();
  }

  Future<List<Meter>> _loadPage() async {
    final page = _q.isEmpty
        ? await _repo.getLocalPage(
            offset: _offset,
            limit: _pageSize,
            unreadOnly: true,
          )
        : await _repo.searchLocalPage(_q, offset: _offset, limit: _pageSize);

    _offset += page.length;
    if (page.length < _pageSize) _hasMore = false;

    final current = state.value ?? <Meter>[];
    return [...current, ...page];
  }

  bool get hasMore => _hasMore;

  Future<void> refreshAll() async {
    // state = const AsyncLoading();
    _offset = 0;
    _hasMore = true;
    _loadingMore = false;

    state = await AsyncValue.guard(() async {
      await _repo.syncAll(pageSize: 500, wipeBefore: true);
      return await _loadPage();
    });
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final combined = await _loadPage();
      state = AsyncData(combined);
    } finally {
      _loadingMore = false;
    }
  }

  /// Force un refresh complet en triggant le rebuild du provider
  void forceRefresh() {
    ref.read(meterRefreshTriggerProvider.notifier).update((state) => state + 1);
  }

  Future<void> refreshAllMeters() async {
    // Reset l'état interne du pager
    _offset = 0;
    _hasMore = true;
    _loadingMore = false;

    // Recharge la première page depuis la DB locale
    state = await AsyncValue.guard(() async {
      return await _loadPage();
    });
  }
}

/// Helper function to trigger meter refresh from anywhere
void refreshMeters(WidgetRef ref) {
  ref.read(meterRefreshTriggerProvider.notifier).update((state) => state + 1);
}

final selectedMeterProvider = StateProvider<Meter?>((ref) => null);
