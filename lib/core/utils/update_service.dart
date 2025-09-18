import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String _portName = 'downloader_send_port';
  static final UpdateService _instance = UpdateService._internal();

  factory UpdateService() => _instance;

  UpdateService._internal();

  ReceivePort? _port;
  String? _currentTaskId;
  Function(int)? _onProgress;
  Function()? _onComplete;
  Function(String)? _onError;

  // Initialiser le service (à appeler dans main())
  static Future<void> initialize() async {
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: false, // Mettre à true si problèmes SSL
    );
  }

  // Enregistrer le callback pour les mises à jour
  void registerCallback({
    Function(int)? onProgress,
    Function()? onComplete,
    Function(String)? onError,
  }) {
    _onProgress = onProgress;
    _onComplete = onComplete;
    _onError = onError;

    // Configurer le port de communication
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);

    _port!.listen((dynamic data) {
      final String taskId = data[0];
      final DownloadTaskStatus status = DownloadTaskStatus.values[data[1]];
      final int progress = data[2];

      debugPrint(
        'Téléchargement: $taskId - Status: $status - Progress: $progress%',
      );

      if (taskId == _currentTaskId) {
        _handleDownloadUpdate(status, progress);
      }
    });

    // Enregistrer le callback statique
    FlutterDownloader.registerCallback(downloadCallback);
  }

  // Callback statique pour l'isolate
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send?.send([id, status, progress]);
  }

  void _handleDownloadUpdate(DownloadTaskStatus status, int progress) {
    switch (status) {
      case DownloadTaskStatus.running:
        _onProgress?.call(progress);
        break;

      case DownloadTaskStatus.complete:
        debugPrint('Téléchargement terminé');
        _onComplete?.call();
        _installApk();
        break;

      case DownloadTaskStatus.failed:
        _onError?.call('Échec du téléchargement');
        break;

      case DownloadTaskStatus.canceled:
        _onError?.call('Téléchargement annulé');
        break;

      case DownloadTaskStatus.paused:
        debugPrint('Téléchargement en pause');
        break;

      default:
        break;
    }
  }

  // Démarrer le téléchargement
  Future<bool> downloadUpdate({
    required String version,
    required String url,
  }) async {
    try {
      // Vérifier les permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _onError?.call('Permissions refusées');
        return false;
      }

      // Obtenir le répertoire de téléchargement
      Directory? directory;
      if (Platform.isAndroid) {
        // Utiliser le dossier Downloads public
        directory = Directory('/storage/emulated/0/Download');

        // Fallback si le dossier n'existe pas
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        _onError?.call('Impossible de trouver le dossier de téléchargement');
        return false;
      }

      final savedDir = directory.path;
      final fileName = 'app_update_$version.apk';

      debugPrint('Téléchargement vers: $savedDir/$fileName');
      debugPrint('URL: $url');

      // Supprimer l'ancienne version si elle existe
      final oldFile = File('$savedDir/$fileName');
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // Lancer le téléchargement
      _currentTaskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: fileName,
        showNotification: true, // Notification dans la barre de statut
        openFileFromNotification: false, // On gère nous-même l'ouverture
        saveInPublicStorage: true, // Sauvegarder dans le stockage public
      );

      return _currentTaskId != null;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement: $e');
      _onError?.call('Erreur: $e');
      return false;
    }
  }

  // Vérifier les permissions
  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      // Permission pour installer des APK
      if (await Permission.requestInstallPackages.isDenied) {
        await Permission.requestInstallPackages.request();
      }

      // Permission de notification pour Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // Permission de stockage pour Android < 11
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < 30) {
        if (await Permission.storage.isDenied) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Installer l'APK téléchargé
  Future<void> _installApk() async {
    if (_currentTaskId == null) return;

    try {
      // Récupérer les infos du téléchargement
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$_currentTaskId'",
      );

      if (tasks == null || tasks.isEmpty) {
        _onError?.call('Fichier téléchargé introuvable');
        return;
      }

      final task = tasks.first;
      final filePath = '${task.savedDir}/${task.filename}';

      debugPrint('Installation de: $filePath');

      // Ouvrir le fichier APK pour l'installation
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        _onError?.call('Erreur d\'installation: ${result.message}');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'installation: $e');
      _onError?.call('Erreur d\'installation: $e');
    }
  }

  // Mettre en pause le téléchargement
  Future<void> pauseDownload() async {
    if (_currentTaskId != null) {
      await FlutterDownloader.pause(taskId: _currentTaskId!);
    }
  }

  // Reprendre le téléchargement
  Future<void> resumeDownload() async {
    if (_currentTaskId != null) {
      final newTaskId = await FlutterDownloader.resume(taskId: _currentTaskId!);
      _currentTaskId = newTaskId;
    }
  }

  // Annuler le téléchargement
  Future<void> cancelDownload() async {
    if (_currentTaskId != null) {
      await FlutterDownloader.cancel(taskId: _currentTaskId!);
    }
  }

  // Réessayer le téléchargement
  Future<void> retryDownload() async {
    if (_currentTaskId != null) {
      final newTaskId = await FlutterDownloader.retry(taskId: _currentTaskId!);
      _currentTaskId = newTaskId;
    }
  }

  // Nettoyer
  void dispose() {
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);
  }
}
