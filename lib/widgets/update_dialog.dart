// lib/widgets/update_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final String apkUrl;

  const UpdateDialog({super.key, required this.version, required this.apkUrl});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double progress = 0.0;
  bool downloading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Debug: afficher l'URL
    debugPrint("APK URL: ${widget.apkUrl}");
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      errorMessage = null;
      downloading = true;
      progress = 0.0;
    });

    try {
      // 1. Vérifier et demander les permissions
      if (Platform.isAndroid) {
        // Pour Android 11+ (API 30+), on n'a plus besoin de WRITE_EXTERNAL_STORAGE
        // mais on a besoin de REQUEST_INSTALL_PACKAGES
        if (await Permission.requestInstallPackages.isDenied) {
          await Permission.requestInstallPackages.request();
        }

        // Pour les anciennes versions d'Android
        final sdkInt = await _getSdkInt();
        if (sdkInt < 30) {
          final storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            setState(() {
              errorMessage = "Permission de stockage refusée";
              downloading = false;
            });
            return;
          }
        }
      }

      // 2. Obtenir le répertoire de téléchargement approprié
      Directory? dir;
      if (Platform.isAndroid) {
        // Utiliser le répertoire de téléchargements public
        dir = await getExternalStorageDirectory();
        dir ??= await getTemporaryDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      // 3. Créer le chemin de sauvegarde
      final fileName = "app_update_${widget.version}.apk";
      final savePath = "${dir.path}/$fileName";

      debugPrint("Téléchargement vers: $savePath");

      // 4. Supprimer l'ancien fichier s'il existe
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 5. Configurer Dio avec timeout et headers
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          headers: {'Accept': '*/*', 'User-Agent': 'MeterSync/1.0'},
        ),
      );

      // 6. Télécharger le fichier
      final response = await dio.download(
        widget.apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
            debugPrint(
              "Téléchargement: ${(progress * 100).toStringAsFixed(0)}%",
            );
          }
        },
        deleteOnError: true,
      );

      debugPrint("Téléchargement terminé, code: ${response.statusCode}");

      // 7. Vérifier que le fichier existe et n'est pas vide
      if (!await file.exists()) {
        throw Exception("Le fichier téléchargé n'existe pas");
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception("Le fichier téléchargé est vide");
      }

      debugPrint("Fichier téléchargé: $fileSize octets");

      setState(() => downloading = false);

      // 8. Ouvrir le fichier APK pour l'installation
      final result = await OpenFilex.open(savePath);
      debugPrint("Résultat de l'ouverture: ${result.message}");

      if (result.type != ResultType.done) {
        setState(() {
          errorMessage = "Impossible d'ouvrir le fichier: ${result.message}";
        });
      }
    } on DioException catch (e) {
      debugPrint("Erreur Dio: ${e.message}");
      debugPrint("Erreur response: ${e.response?.data}");
      setState(() {
        downloading = false;
        errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      debugPrint("Erreur générale: $e");
      setState(() {
        downloading = false;
        errorMessage = "Erreur: $e";
      });
    }
  }

  Future<int> _getSdkInt() async {
    if (Platform.isAndroid) {
      // Obtenir la version SDK Android
      try {
        final info = await Process.run('getprop', ['ro.build.version.sdk']);
        return int.tryParse(info.stdout.toString().trim()) ?? 29;
      } catch (e) {
        return 29; // Valeur par défaut
      }
    }
    return 0;
  }

  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return "Délai de connexion dépassé";
      case DioExceptionType.receiveTimeout:
        return "Délai de téléchargement dépassé";
      case DioExceptionType.badResponse:
        return "Erreur serveur: ${error.response?.statusCode}";
      case DioExceptionType.connectionError:
        return "Erreur de connexion réseau";
      default:
        return error.message ?? "Erreur de téléchargement";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Mise à jour disponible"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Nouvelle version ${widget.version} disponible"),
          const SizedBox(height: 16),

          if (downloading) ...[
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text("${(progress * 100).toStringAsFixed(0)}%"),
          ],

          if (errorMessage != null) ...[
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],

          if (!downloading && errorMessage == null)
            const Text("Voulez-vous installer la nouvelle version ?"),
        ],
      ),
      actions: [
        if (!downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Plus tard"),
          ),
        TextButton(
          onPressed: downloading ? null : _downloadAndInstall,
          child: Text(
            downloading
                ? "Téléchargement..."
                : (errorMessage != null ? "Réessayer" : "Mettre à jour"),
          ),
        ),
      ],
    );
  }
}
