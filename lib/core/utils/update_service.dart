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
  String? _downloadedFilePath; // Stocker le chemin du fichier téléchargé
  Function(int)? _onProgress;
  Function()? _onComplete;
  Function(String)? _onError;
  bool _autoInstallEnabled = false; // Contrôle de l'installation automatique

  // Initialiser le service (à appeler dans main())
  static Future<void> initialize() async {
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: false, // Mettre à true si problèmes SSL
    );
  }

  // Configurer l'installation automatique
  void setAutoInstall(bool enabled) {
    _autoInstallEnabled = enabled;
  }

  // Enregistrer le callback pour les mises à jour
  void registerCallback({
    Function(int)? onProgress,
    Function()? onComplete,
    Function(String)? onError,
    bool autoInstall = false, // Paramètre optionnel pour l'auto-installation
  }) {
    _onProgress = onProgress;
    _onComplete = onComplete;
    _onError = onError;
    _autoInstallEnabled = autoInstall;

    // Configurer le port de communication
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);

    _port!.listen((dynamic data) {
      final String taskId = data[0];
      final DownloadTaskStatus status = DownloadTaskStatus.values[data[1]];
      final int progress = data[2];

      debugPrint('Загрузка: $taskId - Статус: $status - Прогресс: $progress%');

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
        debugPrint('Загрузка завершена');
        _saveDownloadedFilePath(); // Sauvegarder le chemin du fichier
        _onComplete?.call();

        // Installation automatique seulement si activée
        if (_autoInstallEnabled) {
          Future.delayed(const Duration(seconds: 1), () {
            installUpdate();
          });
        }
        break;

      case DownloadTaskStatus.failed:
        _onError?.call('Ошибка загрузки');
        break;

      case DownloadTaskStatus.canceled:
        _onError?.call('Загрузка отменена');
        break;

      case DownloadTaskStatus.paused:
        debugPrint('Загрузка приостановлена');
        break;

      default:
        break;
    }
  }

  // Sauvegarder le chemin du fichier téléchargé
  Future<void> _saveDownloadedFilePath() async {
    if (_currentTaskId == null) return;

    try {
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$_currentTaskId'",
      );

      if (tasks != null && tasks.isNotEmpty) {
        final task = tasks.first;
        _downloadedFilePath = '${task.savedDir}/${task.filename}';
        debugPrint('Файл сохранён: $_downloadedFilePath');
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении пути файла: $e');
    }
  }

  // Démarrer le téléchargement
  Future<bool> downloadUpdate({
    required String version,
    required String url,
    bool autoInstall = false, // Paramètre optionnel
  }) async {
    try {
      _autoInstallEnabled = autoInstall;

      // Vérifier les permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        _onError?.call('Разрешения отклонены');
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
        _onError?.call('Не удалось найти папку для загрузки');
        return false;
      }

      final savedDir = directory.path;
      final fileName = 'app_update_$version.apk';

      debugPrint('Загрузка в: $savedDir/$fileName');
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
      debugPrint('Ошибка при загрузке: $e');
      _onError?.call('Ошибка: $e');
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

  // Méthode publique pour installer l'APK
  Future<void> installUpdate() async {
    // Utiliser le chemin sauvegardé ou le récupérer
    if (_downloadedFilePath != null) {
      await _installApkFromPath(_downloadedFilePath!);
    } else if (_currentTaskId != null) {
      await _installApkFromTaskId();
    } else {
      _onError?.call('Файл обновления не найден');
    }
  }

  // Installer l'APK depuis un chemin spécifique
  Future<void> _installApkFromPath(String filePath) async {
    try {
      debugPrint('Установка: $filePath');

      // Vérifier que le fichier existe
      final file = File(filePath);
      if (!await file.exists()) {
        _onError?.call('Файл не найден: $filePath');
        return;
      }

      // Ouvrir le fichier APK pour l'installation
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        _onError?.call('Ошибка установки: ${result.message}');
      } else {
        debugPrint('Установка запущена успешно');
      }
    } catch (e) {
      debugPrint('Ошибка при установке: $e');
      _onError?.call('Ошибка установки: $e');
    }
  }

  // Installer l'APK depuis l'ID de tâche
  Future<void> _installApkFromTaskId() async {
    if (_currentTaskId == null) return;

    try {
      // Récupérer les infos du téléchargement
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$_currentTaskId'",
      );

      if (tasks == null || tasks.isEmpty) {
        _onError?.call('Загруженный файл не найден');
        return;
      }

      final task = tasks.first;
      final filePath = '${task.savedDir}/${task.filename}';
      _downloadedFilePath = filePath; // Sauvegarder pour usage futur

      await _installApkFromPath(filePath);
    } catch (e) {
      debugPrint('Ошибка при установке: $e');
      _onError?.call('Ошибка установки: $e');
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
      _currentTaskId = null;
      _downloadedFilePath = null;
    }
  }

  // Réessayer le téléchargement
  Future<void> retryDownload() async {
    if (_currentTaskId != null) {
      final newTaskId = await FlutterDownloader.retry(taskId: _currentTaskId!);
      _currentTaskId = newTaskId;
    }
  }

  // Vérifier si un fichier de mise à jour existe
  Future<bool> hasDownloadedUpdate() async {
    if (_downloadedFilePath != null) {
      final file = File(_downloadedFilePath!);
      return await file.exists();
    }
    return false;
  }

  // Obtenir le pourcentage de progression actuel
  int? getCurrentProgress() {
    // Cette méthode pourrait être utile pour restaurer l'état
    // Vous pourriez stocker la progression dans une variable membre
    return null;
  }

  // Nettoyer
  void dispose() {
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    _currentTaskId = null;
    _downloadedFilePath = null;
    _autoInstallEnabled = false;
  }

  // Réinitialiser le service (utile pour les tests)
  void reset() {
    _currentTaskId = null;
    _downloadedFilePath = null;
    _autoInstallEnabled = false;
  }
}
