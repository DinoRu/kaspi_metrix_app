import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription; // Updated type
  static bool _isOnline = true;

  /// Initialize connectivity monitoring
  static void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results, // Updated to List<ConnectivityResult>
    ) {
      _updateConnectionStatus(results);
    });

    // Check initial connectivity
    checkInitialConnectivity();
  }

  /// Check initial connectivity
  static Future<void> checkInitialConnectivity() async {
    try {
      final results = await _connectivity
          .checkConnectivity(); // Returns List<ConnectivityResult>
      _updateConnectionStatus(results);
    } catch (e) {
      print('Error checking initial connectivity: $e');
      _isOnline = false;
    }
  }

  /// Update connection status
  static void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if any result indicates connectivity
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Perform additional verification if connected
    if (_isOnline) {
      _verifyInternetAccess();
    }
  }

  /// Verify actual internet access (not just connectivity)
  static Future<void> _verifyInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _isOnline = false;
    }
  }

  /// Returns true if the device is online
  static bool get isOnline => _isOnline;

  /// Returns true if the device is offline
  static bool get isOffline => !_isOnline;

  /// Check connectivity asynchronously
  static Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity
          .checkConnectivity(); // Returns List<ConnectivityResult>
      if (!results.any((result) => result != ConnectivityResult.none)) {
        return false;
      }

      // Test ping to verify actual internet access
      final internetResult = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return internetResult.isNotEmpty &&
          internetResult[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Stream to listen for connectivity changes
  static Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.asyncMap((
      List<ConnectivityResult> results, // Updated to List<ConnectivityResult>
    ) async {
      if (!results.any((result) => result != ConnectivityResult.none)) {
        return false;
      }
      return await checkConnectivity();
    });
  }

  /// Clean up resources
  static void dispose() {
    _connectivitySubscription?.cancel();
  }
}
