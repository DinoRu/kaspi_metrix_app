// lib/core/services/update_checker.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:metrix/config/constants.dart';
import 'package:metrix/core/network/api_client.dart';
import 'package:metrix/widgets/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  static final UpdateChecker _instance = UpdateChecker._internal();
  factory UpdateChecker() => _instance;
  UpdateChecker._internal();

  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Timer? _periodicTimer;
  bool _isChecking = false;
  String? _currentVersion;
  String? _lastCheckedServerVersion;
  DateTime? _lastCheckTime;

  // Configuration
  static const Duration _checkInterval = Duration(
    hours: 4,
  ); // Vérifier toutes les 4 heures
  static const Duration _minimumCheckGap = Duration(
    minutes: 30,
  ); // Éviter les vérifications trop fréquentes

  /// Initialise le service de vérification des mises à jour
  Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
      debugPrint('UpdateChecker: Version actuelle $_currentVersion');
    } catch (e) {
      debugPrint('UpdateChecker: Erreur d\'initialisation $e');
    }
  }

  /// Démarre les vérifications périodiques
  void startPeriodicCheck() {
    stopPeriodicCheck(); // Arrêter tout timer existant

    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      debugPrint('UpdateChecker: Vérification périodique déclenchée');
      checkForUpdate();
    });

    debugPrint(
      'UpdateChecker: Vérifications périodiques démarrées (intervalle: $_checkInterval)',
    );
  }

  /// Arrête les vérifications périodiques
  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    debugPrint('UpdateChecker: Vérifications périodiques arrêtées');
  }

  /// Vérifie s'il y a une mise à jour disponible
  /// [context] est optionnel - si fourni, affiche le dialog de mise à jour
  /// [forceCheck] ignore les limites de temps entre les vérifications
  Future<bool> checkForUpdate({
    BuildContext? context,
    bool forceCheck = false,
  }) async {
    // Éviter les vérifications simultanées
    if (_isChecking) {
      debugPrint('UpdateChecker: Vérification déjà en cours');
      return false;
    }

    // Vérifier si on a déjà vérifié récemment (sauf si forceCheck)
    if (!forceCheck && _lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck < _minimumCheckGap) {
        debugPrint(
          'UpdateChecker: Dernière vérification trop récente (${timeSinceLastCheck.inMinutes} minutes)',
        );
        return false;
      }
    }

    _isChecking = true;
    bool updateAvailable = false;

    try {
      if (_currentVersion == null) {
        await initialize();
      }

      debugPrint('UpdateChecker: Vérification de mise à jour...');
      _lastCheckTime = DateTime.now();

      final response = await _apiClient.dio.get(ApiConstants.apkVersion);

      if (response.statusCode == 200) {
        final data = response.data;
        final serverVersion = data['version'] as String;
        final url = data['url'] as String;

        _lastCheckedServerVersion = serverVersion;

        debugPrint(
          'UpdateChecker: Version serveur $serverVersion, version locale $_currentVersion',
        );

        if (_isNewer(serverVersion, _currentVersion!)) {
          updateAvailable = true;

          // Vérifier si on doit afficher le dialog
          if (context != null && context.mounted) {
            await _showUpdateDialogIfNeeded(context, serverVersion, url);
          }
        }
      }
    } catch (e) {
      debugPrint('UpdateChecker: Erreur lors de la vérification $e');
    } finally {
      _isChecking = false;
    }

    return updateAvailable;
  }

  /// Affiche le dialog de mise à jour si nécessaire
  Future<void> _showUpdateDialogIfNeeded(
    BuildContext context,
    String serverVersion,
    String url,
  ) async {
    try {
      // Vérifier si on a déjà affiché le dialog pour cette version
      final lastShownVersion = await _storage.read(
        key: 'last_shown_update_version',
      );

      if (lastShownVersion == serverVersion) {
        debugPrint(
          'UpdateChecker: Dialog déjà affiché pour la version $serverVersion',
        );
        return;
      }

      // Vérifier si l'utilisateur a choisi "Plus tard" récemment
      final lastDismissedTime = await _storage.read(
        key: 'last_update_dismissed_time',
      );

      if (lastDismissedTime != null) {
        final dismissedDate = DateTime.parse(lastDismissedTime);
        final hoursSinceDismissed = DateTime.now()
            .difference(dismissedDate)
            .inHours;

        // Ne pas afficher le dialog si l'utilisateur a cliqué "Plus tard" dans les dernières 24h
        if (hoursSinceDismissed < 24) {
          debugPrint(
            'UpdateChecker: Dialog reporté (dismissed il y a $hoursSinceDismissed heures)',
          );
          return;
        }
      }

      if (context.mounted) {
        debugPrint('UpdateChecker: Affichage du dialog de mise à jour');

        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(version: serverVersion, apkUrl: url),
        );

        // Stocker la version affichée
        await _storage.write(
          key: 'last_shown_update_version',
          value: serverVersion,
        );

        // Si l'utilisateur a choisi "Plus tard", stocker l'heure
        if (result == false) {
          await _storage.write(
            key: 'last_update_dismissed_time',
            value: DateTime.now().toIso8601String(),
          );
        }
      }
    } catch (e) {
      debugPrint('UpdateChecker: Erreur lors de l\'affichage du dialog $e');
    }
  }

  /// Compare deux versions pour déterminer si la version serveur est plus récente
  bool _isNewer(String server, String local) {
    try {
      final s = server.split('.').map(int.parse).toList();
      final l = local.split('.').map(int.parse).toList();

      // S'assurer que les deux listes ont la même longueur
      final maxLength = s.length > l.length ? s.length : l.length;
      while (s.length < maxLength) s.add(0);
      while (l.length < maxLength) l.add(0);

      for (int i = 0; i < maxLength; i++) {
        if (s[i] > l[i]) return true;
        if (s[i] < l[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint(
        'UpdateChecker: Erreur lors de la comparaison des versions $e',
      );
      return false;
    }
  }

  /// Retourne true si une mise à jour est disponible (basé sur la dernière vérification)
  bool get hasUpdate =>
      _lastCheckedServerVersion != null &&
      _currentVersion != null &&
      _isNewer(_lastCheckedServerVersion!, _currentVersion!);

  /// Force une nouvelle vérification au prochain appel
  void clearCache() {
    _lastCheckTime = null;
    _lastCheckedServerVersion = null;
  }

  /// Nettoie les ressources
  void dispose() {
    stopPeriodicCheck();
  }
}
