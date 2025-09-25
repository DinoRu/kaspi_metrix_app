import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';
import 'package:metrix/config/theme.dart';
import 'package:metrix/presentation/screens/reading_detail_screen.dart';

class ReadingsScreen extends ConsumerWidget {
  const ReadingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(readingsProvider(null));
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    // Handle manual sync
    void handleManualSync() async {
      try {
        await ref.read(syncStatusProvider.notifier).syncNow();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Синхронизация успешно завершена'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.invalidate(readingsProvider(null));
        ref.invalidate(pendingSyncCountProvider);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка синхронизации: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    // Handle refresh
    Future<void> handleRefresh() async {
      // Invalidate the readings provider to force a refresh
      ref.invalidate(readingsProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Показания'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: syncStatus == SyncStatus.syncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                tooltip: 'Синхронизировать показания с сервером',
                onPressed: syncStatus == SyncStatus.syncing
                    ? null
                    : handleManualSync,
              ),
              // Show pending count badge if > 0
              if (pendingCount.asData?.value != null &&
                  pendingCount.asData!.value > 0)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${pendingCount.asData!.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: readings.when(
        data: (readingList) {
          if (readingList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 80,
                    color: MeterSyncTheme.textTertiaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Показания отсутствуют',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Нажмите + для добавления первого показания'),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      // Navigate to reading detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReadingDetailScreen(reading: reading),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: reading.syncStatus == 'synced'
                            ? MeterSyncTheme.successGreen.withOpacity(0.1)
                            : MeterSyncTheme.warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        reading.syncStatus == 'synced'
                            ? Icons.check_circle
                            : Icons.schedule,
                        color: reading.syncStatus == 'synced'
                            ? MeterSyncTheme.successGreen
                            : MeterSyncTheme.warningOrange,
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
                        if (reading.notes != null && reading.notes!.isNotEmpty)
                          Text(
                            'Заметки: ${reading.notes}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    trailing: reading.photos.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: MeterSyncTheme.primaryGreen.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo,
                                  size: 16,
                                  color: MeterSyncTheme.primaryGreen,
                                ),
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
        error: (error, _) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}
