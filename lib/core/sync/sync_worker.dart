import 'package:metrix/data/repositories/reading_repository.dart';
import 'package:metrix/core/network/api_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncWorker {
  static Future<void> performSync() async {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      print('No internet connection, skipping sync');
      return;
    }

    try {
      print('Starting sync...');
      final apiClient = ApiClient();
      final readingRepo = ReadingRepository(apiClient);
      await readingRepo.syncReadings();
      print('Sync completed successfully');
    } catch (e) {
      print('Sync error: $e');
    }
  }
}
