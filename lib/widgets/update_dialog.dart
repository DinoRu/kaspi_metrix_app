import 'package:flutter/material.dart';
import 'package:metrix/core/utils/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final String apkUrl;
  final bool autoInstall; // Параметр для автоматической установки

  const UpdateDialog({
    super.key,
    required this.version,
    required this.apkUrl,
    this.autoInstall = false, // По умолчанию ручная установка
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();

  bool _downloading = false;
  bool _downloadComplete = false;
  bool _installing = false;
  int _progress = 0;
  String? _errorMessage;
  bool _downloadStarted = false;
  bool _autoInstallEnabled = false; // Предпочтение пользователя

  @override
  void initState() {
    super.initState();
    _autoInstallEnabled = widget.autoInstall;
    _setupUpdateService();
  }

  void _setupUpdateService() {
    _updateService.registerCallback(
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _downloading = true;
            _downloadComplete = false;
          });
        }
      },
      onComplete: () async {
        if (mounted) {
          setState(() {
            _downloading = false;
            _downloadComplete = true;
            _progress = 100;
          });

          // Si l'installation automatique est activée
          if (_autoInstallEnabled) {
            // Attendre un peu pour montrer le succès
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              setState(() {
                _installing = true;
              });

              // L'installation sera lancée automatiquement par le service
              // Fermer le dialog après un délai
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            }
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _downloading = false;
            _downloadComplete = false;
            _installing = false;
            _errorMessage = error;
          });
        }
      },
      autoInstall: _autoInstallEnabled, // Passer le paramètre au service
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _downloadStarted = true;
      _downloadComplete = false;
      _errorMessage = null;
      _progress = 0;
    });

    // Mettre à jour l'état d'auto-installation dans le service
    _updateService.setAutoInstall(_autoInstallEnabled);

    final success = await _updateService.downloadUpdate(
      version: widget.version,
      url: widget.apkUrl,
      autoInstall: _autoInstallEnabled, // Passer le paramètre
    );

    if (!success && mounted) {
      setState(() {
        _downloading = false;
        _errorMessage = 'Не удалось начать загрузку';
      });
    }
  }

  Future<void> _installUpdate() async {
    setState(() {
      _installing = true;
    });

    // Запустить установку
    await _updateService.installUpdate();

    // Закрыть диалог после запуска установки
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _downloadInBackground() {
    // Закрыть диалог, но продолжить загрузку
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _autoInstallEnabled
              ? 'Загрузка в фоновом режиме. Автоматическая установка после загрузки.'
              : 'Загрузка в фоновом режиме. Вы будете уведомлены по завершении.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _downloadComplete
                ? Icons.check_circle
                : (_installing ? Icons.install_mobile : Icons.system_update),
            color: _downloadComplete ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            _installing
                ? 'Установка...'
                : (_downloadComplete
                      ? 'Загрузка завершена'
                      : 'Доступно обновление'),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_downloadComplete && !_installing)
            Text(
              'Версия ${widget.version} доступна',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),

          // Состояние: Установка
          if (_installing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Установка выполняется...\nПриложение будет перезапущено.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ]
          // Состояние: Загрузка
          else if (_downloading) ...[
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_progress%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Идёт загрузка...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Чекбокс для автоматической установки во время загрузки
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _autoInstallEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoInstallEnabled = value ?? false;
                    });
                    // Обновить настройку в сервисе
                    _updateService.setAutoInstall(_autoInstallEnabled);
                  },
                ),
                const Flexible(
                  child: Text(
                    'Установить автоматически после загрузки',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ]
          // Состояние: Загрузка завершена (без автоустановки)
          else if (_downloadComplete && !_autoInstallEnabled) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Загрузка завершена!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Обновление готово к установке.\nХотите установить сейчас?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ]
          // Состояние: Загрузка завершена (с автоустановкой)
          else if (_downloadComplete &&
              _autoInstallEnabled &&
              !_installing) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Загрузка завершена!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Автоматическая установка через несколько секунд...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ]
          // Состояние: Ошибка
          else if (_errorMessage != null) ...[
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ]
          // Состояние: Начальное
          else ...[
            const Icon(Icons.download_rounded, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Доступна новая версия.\nХотите загрузить сейчас?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Чекбокс для автоматической установки перед началом
            CheckboxListTile(
              value: _autoInstallEnabled,
              onChanged: (value) {
                setState(() {
                  _autoInstallEnabled = value ?? false;
                });
                // Обновить настройку в сервисе
                _updateService.setAutoInstall(_autoInstallEnabled);
              },
              title: const Text(
                'Установить автоматически',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Обновление будет установлено сразу после загрузки',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
      actions: [
        // Кнопки в зависимости от состояния
        if (_installing) ...[
          // Нет кнопок во время установки
        ] else if (_downloading) ...[
          TextButton(
            onPressed: _downloadInBackground,
            child: const Text('В фоне'),
          ),
          TextButton(
            onPressed: () {
              _updateService.pauseDownload();
              setState(() {
                _downloading = false;
                _downloadStarted = false;
              });
            },
            child: const Text('Пауза', style: TextStyle(color: Colors.orange)),
          ),
        ] else if (_downloadComplete && !_autoInstallEnabled) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Позже'),
          ),
          ElevatedButton(
            onPressed: _installUpdate,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Установить сейчас'),
          ),
        ] else if (_downloadComplete &&
            _autoInstallEnabled &&
            !_installing) ...[
          // Автоматическая установка скоро начнется
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ] else if (_errorMessage != null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Повторить'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Позже'),
          ),
          ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download),
            label: Text(
              _autoInstallEnabled ? 'Загрузить и установить' : 'Загрузить',
            ),
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
