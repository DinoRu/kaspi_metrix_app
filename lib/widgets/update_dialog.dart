import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:install_plugin/install_plugin.dart';

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

  Future<void> _downloadAndInstall() async {
    try {
      setState(() {
        downloading = true;
        progress = 0.0;
      });

      final dir = await getExternalStorageDirectory();
      final savePath = "${dir!.path}/my_app_${widget.version}.apk";

      final dio = Dio();
      await dio.download(
        widget.apkUrl,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              progress = count / total;
            });
          }
        },
      );

      setState(() => downloading = false);

      await InstallPlugin.installApk(savePath).catchError((e) {
        debugPrint("Erreur install: $e");
      });
    } catch (e) {
      setState(() => downloading = false);
      debugPrint("Erreur download/install: $e");
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
          const SizedBox(height: 10),
          if (downloading)
            LinearProgressIndicator(value: progress)
          else
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
          child: downloading
              ? Text("${(progress * 100).toStringAsFixed(0)}%")
              : const Text("Mettre à jour"),
        ),
      ],
    );
  }
}
