// lib/presentation/screens/meters_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:metrix/config/constants.dart';
import 'package:metrix/config/theme.dart';
import 'package:metrix/core/network/api_client.dart';
import 'package:metrix/data/models/meter.dart';
import 'package:metrix/presentation/providers/meter_provider.dart';
import 'package:metrix/presentation/widgets/meter_search_delagate.dart';
import 'package:metrix/widgets/custom_widgets.dart';
import 'package:metrix/widgets/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MetersScreen extends ConsumerStatefulWidget {
  const MetersScreen({super.key});

  @override
  ConsumerState<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends ConsumerState<MetersScreen> with RouteAware {
  final _scrollCtrl = ScrollController();
  bool _showScrollToTopButton = false;
  final ApiClient _apiClient = ApiClient();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _hasCheckedUpdateThisSession = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);

    // Force un refresh à chaque fois qu'on arrive sur cet écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(metersPagerProvider);
      _checkAppUpdate();
    });
  }

  void _onScroll() {
    final notifier = ref.read(metersPagerProvider.notifier);

    // Logique pour charger plus d'éléments
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      notifier.loadMore();
    }

    // Logique pour afficher/masquer le bouton scroll to top
    if (_scrollCtrl.position.pixels > 300) {
      if (!_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = true;
        });
      }
    } else {
      if (_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  } // instance de ton ApiClient

  Future<void> _checkAppUpdate() async {
    if (_hasCheckedUpdateThisSession) return; // déjà vérifié
    _hasCheckedUpdateThisSession = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      print('Version $currentVersion');

      final lastShownVersion = await _storage.read(
        key: 'last_shown_update_version',
      );
      if (lastShownVersion != null && lastShownVersion == currentVersion) {
        // L'utilisateur a déjà vu le dialog pour cette version
        return;
      }

      final response = await _apiClient.dio.get(ApiConstants.apkVersion);
      if (response.statusCode == 200) {
        final data = response.data;
        final serverVersion = data['version'] as String;
        final url = data['url'] as String;

        if (_isNewer(serverVersion, currentVersion)) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => UpdateDialog(version: serverVersion, apkUrl: url),
            );
            // Stocker la version pour ne plus afficher ce dialog
            await _storage.write(
              key: 'last_shown_update_version',
              value: serverVersion,
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur check update: $e");
    }
  }

  bool _isNewer(String server, String local) {
    final s = server.split('.').map(int.parse).toList();
    final l = local.split('.').map(int.parse).toList();
    for (int i = 0; i < s.length; i++) {
      if (s[i] > l[i]) return true;
      if (s[i] < l[i]) return false;
    }
    return false;
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshAllMeters() async {
    ref.invalidate(allMetersCacheFirstProvider);
  }

  @override
  Widget build(BuildContext context) {
    // final pager = ref.watch(metersPagerProvider);
    final notifier = ref.read(metersPagerProvider.notifier);
    final allmeters = ref.watch(allMetersCacheFirstProvider);
    final hasMore = ref.watch(metersHasMoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Счётчики'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              allmeters.when(
                data: (meters) => showSearch(
                  context: context,
                  delegate: CustomSearchDelegate<Meter>(
                    list: meters,
                    searchFields: (item) => [
                      item.meterNumber ?? '',
                      item.locationAddress ?? '',
                      item.clientName ?? '',
                    ],
                    onItemTap: (context, item) {
                      Navigator.pushNamed(
                        context,
                        "/reading/new",
                        arguments: item,
                      );
                    },
                  ),
                ),
                loading: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Загрузка счётчиков...')),
                  );
                },
                error: (err, st) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка загрузки счётчиков: $err')),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Синхронизировать все с сервера',
            onPressed: () => notifier.refreshAll(),
          ),
        ],
      ),
      body: allmeters.when(
        data: (meterList) {
          if (meterList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.speed,
                    size: 80,
                    color: MeterSyncTheme.textTertiaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Счётчики не найдены',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: notifier.refreshAll,
                    child: const Text('Обновить'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAllMeters,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: meterList.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= meterList.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final meter = meterList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MeterCard(
                    meterNumber: meter.meterNumber ?? "",
                    type: meter.type ?? "",
                    address:
                        meter.locationAddress ?? 'Неизвестное местоположение',
                    lastReading: meter.lastReadingDate?.toString(),
                    // SIMPLIFIÉ : Plus besoin de gestion manuelle du refresh
                    // Le refresh se fait automatiquement via le trigger provider
                    onTap: () {
                      ref.read(selectedMeterProvider.notifier).state = meter;
                      Navigator.pushNamed(
                        context,
                        '/reading/new',
                        arguments: meter,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка счётчиков...'),
            ],
          ),
        ),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $err'),
              const SizedBox(height: 8),
              Text(
                '$st',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: notifier.refreshAll,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: 'Вернуться наверх',
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
    );
  }
}
