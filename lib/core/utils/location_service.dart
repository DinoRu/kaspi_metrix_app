import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:metrix/core/utils/connectivity_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _lastLocationKey = 'last_known_location';
  static const Duration _locationTimeout = Duration(seconds: 30);
  static const Duration _offlineTimeout = Duration(seconds: 60);

  /// Obtient la position actuelle avec gestion offline améliorée
  static Future<Position?> getCurrentLocation({
    bool isOfflineMode = false,
  }) async {
    try {
      // Vérifier les permissions
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      // Paramètres optimisés pour offline/online
      LocationSettings locationSettings = _getLocationSettings(isOfflineMode);

      // Essayer d'obtenir la position avec timeout adaptatif
      Duration timeout = isOfflineMode ? _offlineTimeout : _locationTimeout;

      Position? position = await _getCurrentPositionWithTimeout(
        locationSettings,
        timeout,
      );

      if (position != null) {
        // Sauvegarder la position pour usage offline
        await _saveLastKnownLocation(position);
        return position;
      }

      // Si échec, utiliser la dernière position connue
      return await _getLastKnownLocation();
    } catch (e) {
      print('Error getting current location: $e');
      // En cas d'erreur, retourner la dernière position connue
      return await _getLastKnownLocation();
    }
  }

  /// Obtient la dernière position connue
  static Future<Position?> getLastKnownLocation() async {
    try {
      // Essayer d'abord la dernière position du système
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await _saveLastKnownLocation(lastKnown);
        return lastKnown;
      }

      // Sinon, utiliser notre cache local
      return await _getLastKnownLocation();
    } catch (e) {
      print('Error getting last known location: $e');
      return await _getLastKnownLocation();
    }
  }

  /// Obtient la position avec timeout personnalisé
  static Future<Position?> _getCurrentPositionWithTimeout(
    LocationSettings settings,
    Duration timeout,
  ) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(timeout);
    } on TimeoutException {
      print('Location timeout - trying with lower accuracy');
      // Essayer avec une précision réduite si timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 0,
        ),
      ).timeout(Duration(seconds: 15));
    } catch (e) {
      print('Error in getCurrentPositionWithTimeout: $e');
      return null;
    }
  }

  /// Sauvegarde la dernière position connue
  static Future<void> _saveLastKnownLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
      };
      await prefs.setString(_lastLocationKey, json.encode(locationData));
    } catch (e) {
      print('Error saving last known location: $e');
    }
  }

  /// Récupère la dernière position sauvegardée
  static Future<Position?> _getLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationString = prefs.getString(_lastLocationKey);

      if (locationString != null) {
        final locationData = json.decode(locationString);
        return Position(
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            locationData['timestamp'],
          ),
          accuracy: locationData['accuracy'],
          altitude: locationData['altitude'] ?? 0,
          heading: locationData['heading'] ?? 0,
          speed: locationData['speed'] ?? 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      print('Error getting cached location: $e');
    }
    return null;
  }

  /// Vérifie si l'appareil est en mode offline (version améliorée)
  static Future<bool> isOfflineMode() async {
    return !await ConnectivityHelper.checkConnectivity();
  }

  /// Configuration des paramètres de localisation selon le mode
  static LocationSettings _getLocationSettings(bool isOfflineMode) {
    if (isOfflineMode) {
      // Paramètres optimisés pour offline (GPS uniquement)
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 60),
      );
    } else {
      // Paramètres optimisés pour online (GPS + réseau)
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 30),
      );
    }
  }

  /// Vérifie et demande les permissions de localisation
  static Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Stream pour écouter les changements de position
  static Stream<Position> getPositionStream({bool isOfflineMode = false}) {
    LocationSettings settings = _getLocationSettings(isOfflineMode);

    return Geolocator.getPositionStream(locationSettings: settings).handleError(
      (error) {
        print('Position stream error: $error');
      },
    );
  }

  /// Obtient la position avec détection automatique du mode
  static Future<Position?> getCurrentLocationAuto() async {
    bool isOffline = await isOfflineMode();
    return getCurrentLocation(isOfflineMode: isOffline);
  }

  static double? calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
