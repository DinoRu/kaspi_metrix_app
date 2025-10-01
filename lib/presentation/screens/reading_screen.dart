// lib/presentation/screens/readings_screen.dart - VERSION AVEC SYNC AUTOMATIQUE

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/config/theme.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';
import 'package:metrix/presentation/providers/sync_provider.dart';
import 'package:metrix/presentation/screens/reading_detail_screen.dart';
import 'package:metrix/presentation/widgets/sync_status_indicator.dart';

class ReadingsScreen extends ConsumerWidget {
  const ReadingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(readingsProvider(null));
    final syncInfo = ref.watch(syncInfoProvider);

    // Rafraîchir les données
    Future<void> handleRefresh() async {
      // Invalider le provider pour forcer le rechargement
      ref.invalidate(readingsProvider);

      // Si il y a des éléments en attente et qu'on est en ligne, synchroniser
      // if (syncInfo.hasPendingItems && !syncInfo.isOffline) {
      //   await ref.read(manualSyncProvider.future);
      // }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Показания'),
        actions: [
          // Indicateur de statut dans l'AppBar
          const Padding(padding: EdgeInsets.only(right: 12), child: SyncStatusIcon()),
        ],
      ),
      body: SyncStatusWrapper(
        showBanner: true, // Afficher la bannière de statut
        child: readings.when(
          data: (readingList) {
            if (readingList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article_outlined, size: 80, color: MeterSyncTheme.textTertiaryLight),
                    const SizedBox(height: 16),
                    Text('Показания отсутствуют', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    // const Text('Нажмите + для добавления первого показания'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: handleRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                itemCount: readingList.length,
                itemBuilder: (context, index) {
                  final reading = readingList[index];
                  final isSynced = reading.syncStatus == 'synced';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReadingDetailScreen(reading: reading),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSynced
                              ? MeterSyncTheme.successGreen.withOpacity(0.1)
                              : MeterSyncTheme.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            key: ValueKey(isSynced),
                            isSynced ? Icons.cloud_done : Icons.cloud_upload,
                            color: isSynced
                                ? MeterSyncTheme.successGreen
                                : MeterSyncTheme.warningOrange,
                          ),
                        ),
                      ),
                      title: Text(
                        '${reading.readingValue} кВт·ч',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Дата: ${reading.readingDate.toString().split('.')[0]}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (!isSynced && syncInfo.isOffline)
                            Text(
                              'Будет синхронизировано при подключении',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (!isSynced && !syncInfo.isOffline && !syncInfo.isSyncing)
                            Text(
                              'Ожидает синхронизации',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (reading.notes != null && reading.notes!.isNotEmpty)
                            Text(
                              'Заметки: ${reading.notes}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: reading.photos.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MeterSyncTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo, size: 16, color: MeterSyncTheme.primaryGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${reading.photos.length}',
                                    style: TextStyle(
                                      color: MeterSyncTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка: $error'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(readingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
