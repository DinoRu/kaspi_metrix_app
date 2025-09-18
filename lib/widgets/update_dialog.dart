// lib/widgets/update_dialog.dart

import 'package:flutter/material.dart';
import 'package:metrix/core/utils/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final String apkUrl;

  const UpdateDialog({super.key, required this.version, required this.apkUrl});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();

  bool _downloading = false;
  int _progress = 0;
  String? _errorMessage;
  bool _downloadStarted = false;

  @override
  void initState() {
    super.initState();
    _setupUpdateService();
  }

  void _setupUpdateService() {
    _updateService.registerCallback(
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _downloading = true;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _downloading = false;
            _progress = 100;
          });

          // Fermer le dialog après installation
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _downloading = false;
            _errorMessage = error;
          });
        }
      },
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _downloadStarted = true;
      _errorMessage = null;
      _progress = 0;
    });

    final success = await _updateService.downloadUpdate(
      version: widget.version,
      url: widget.apkUrl,
    );

    if (!success && mounted) {
      setState(() {
        _downloading = false;
        _errorMessage = 'Impossible de démarrer le téléchargement';
      });
    }
  }

  void _downloadInBackground() {
    // Fermer le dialog mais continuer le téléchargement
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement en cours en arrière-plan...'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Mise à jour disponible'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Version ${widget.version} disponible',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_downloading) ...[
            LinearProgressIndicator(value: _progress / 100, minHeight: 6),
            const SizedBox(height: 8),
            Text(
              '$_progress%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Téléchargement en cours...',
              style: TextStyle(fontSize: 12),
            ),
          ] else if (_progress == 100) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Téléchargement terminé!\nInstallation en cours...',
              textAlign: TextAlign.center,
            ),
          ] else if (_errorMessage != null) ...[
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const Icon(Icons.download, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            const Text(
              'Une nouvelle version est disponible.\nVoulez-vous la télécharger maintenant?',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (!_downloading && _progress != 100) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          if (_errorMessage != null)
            TextButton(
              onPressed: _startDownload,
              child: const Text('Réessayer'),
            )
          else
            ElevatedButton(
              onPressed: _startDownload,
              child: const Text('Télécharger'),
            ),
        ] else if (_downloading && _downloadStarted) ...[
          TextButton(
            onPressed: _downloadInBackground,
            child: const Text('Continuer en arrière-plan'),
          ),
          TextButton(
            onPressed: () {
              _updateService.pauseDownload();
              setState(() {
                _downloading = false;
              });
            },
            child: const Text('Pause'),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }
}
