import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/config/theme.dart';
import 'package:metrix/config/app_colors.dart';
import 'package:metrix/data/models/meter.dart';
import 'package:metrix/data/models/reading.dart';
import 'package:metrix/presentation/providers/auth_provider.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';
import 'package:metrix/presentation/providers/meter_provider.dart';
import 'package:metrix/core/utils/location_service.dart';
import 'package:metrix/core/utils/photo_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:metrix/widgets/custom_widgets.dart';

class ReadingFormScreen extends ConsumerStatefulWidget {
  final Meter? meter;

  const ReadingFormScreen({super.key, this.meter});

  @override
  ConsumerState<ReadingFormScreen> createState() => _ReadingFormScreenState();
}

class _ReadingFormScreenState extends ConsumerState<ReadingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _readingValueController = TextEditingController();
  final _notesController = TextEditingController();

  Meter? _selectedMeter;
  DateTime _readingDate = DateTime.now();
  Position? _currentPosition;
  Position? _lastKnownPosition;
  final List<String> _photoPaths = []; // Store local paths
  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isOfflineMode = false;
  LocationStatus _locationStatus = LocationStatus.unknown;

  @override
  void initState() {
    super.initState();
    _selectedMeter = widget.meter;
    _initializeLocation();
  }

  /// Initialise la localisation avec gestion offline
  Future<void> _initializeLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Vérifier le mode offline
      _isOfflineMode = await LocationService.isOfflineMode();

      // Essayer d'obtenir la position actuelle
      await _getCurrentLocation();

      // Si pas de position actuelle, utiliser la dernière connue
      if (_currentPosition == null) {
        _lastKnownPosition = await LocationService.getLastKnownLocation();
        if (_lastKnownPosition != null) {
          setState(() {
            _locationStatus = LocationStatus.lastKnown;
          });
        }
      }
    } catch (e) {
      print('Ошибка инициализации местоположения: $e');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  /// Obtient la position actuelle avec gestion offline
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationStatus = LocationStatus.loading;
    });

    try {
      final position = await LocationService.getCurrentLocation(
        isOfflineMode: _isOfflineMode,
      );

      if (mounted) {
        setState(() {
          if (position != null) {
            _currentPosition = position;
            _locationStatus = LocationStatus.current;

            // Si on était en mode dernière position connue, la mettre à jour
            if (_lastKnownPosition != null) {
              _lastKnownPosition = position;
            }
          } else {
            _locationStatus = LocationStatus.failed;
          }
        });
      }
    } catch (e) {
      print('Ошибка получения местоположения: $e');
      if (mounted) {
        setState(() {
          _locationStatus = LocationStatus.failed;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  /// Widget pour afficher le statut de localisation
  Widget _buildLocationStatusWidget() {
    switch (_locationStatus) {
      case LocationStatus.loading:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Получение местоположения...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isOfflineMode
                          ? 'Используется только GPS (автономный режим)'
                          : 'Используются GPS и сеть',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case LocationStatus.current:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MeterSyncTheme.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MeterSyncTheme.successGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.gps_fixed, color: MeterSyncTheme.successGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Текущее местоположение',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Широта: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                      'Долгота: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_currentPosition!.accuracy > 0)
                      Text(
                        'Точность: ${_currentPosition!.accuracy.toStringAsFixed(1)} м'
                        '${_isOfflineMode ? ' (только GPS)' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _getCurrentLocation,
              ),
            ],
          ),
        );

      case LocationStatus.lastKnown:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MeterSyncTheme.warningOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MeterSyncTheme.warningOrange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_history, color: MeterSyncTheme.warningOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Последнее известное местоположение',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Широта: ${_lastKnownPosition!.latitude.toStringAsFixed(6)}, '
                      'Долгота: ${_lastKnownPosition!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Дата: ${_formatTimestamp(_lastKnownPosition!.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _getCurrentLocation,
              ),
            ],
          ),
        );

      case LocationStatus.failed:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MeterSyncTheme.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MeterSyncTheme.errorRed.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_off, color: MeterSyncTheme.errorRed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Местоположение недоступно',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isOfflineMode
                          ? 'Сигнал GPS не найден (автономный режим)'
                          : 'Проверьте GPS и разрешения',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _getCurrentLocation,
                child: const Text('Повторить'),
              ),
            ],
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_searching, color: Colors.grey),
              SizedBox(width: 12),
              Text('Инициализация местоположения...'),
            ],
          ),
        );
    }
  }

  /// Obtient la position à utiliser pour sauvegarder
  Position? _getPositionToSave() {
    return _currentPosition ?? _lastKnownPosition;
  }

  /// Formate le timestamp pour affichage
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч. назад';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _readingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_readingDate),
      );

      if (time != null) {
        setState(() {
          _readingDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final file = await PhotoService.takePhoto();
    if (file != null) {
      final exifData = await PhotoService.extractExifData(file);
      setState(() {
        _photoPaths.add(file.path);
        if (exifData?['latitude'] != null) {
          _currentPosition = Position(
            latitude: exifData?['latitude'].toDouble(),
            longitude: exifData?['longitude'].toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      });
    }
  }

  // Dans ReadingFormScreen, modifier la méthode _submitReading
  Future<void> _submitReading() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMeter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите счётчик')),
      );
      return;
    }
    if (_photoPaths.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Требуется не менее 2 фотографий')),
      );
      return;
    }

    // Avertir si utilisation de la dernière position connue
    if (_currentPosition == null && _lastKnownPosition != null) {
      final shouldContinue = await _showLocationWarning();
      if (!shouldContinue) return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('Пользователь не аутентифицирован');

      final position = _getPositionToSave();

      final reading = Reading(
        meterId: _selectedMeter!.id,
        userId: user.id,
        readingValue: double.parse(_readingValueController.text),
        readingDate: _readingDate,
        latitude: position?.latitude,
        longitude: position?.longitude,
        accuracyMeters: position?.accuracy,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        photos: _photoPaths,
      );

      await ref
          .read(readingRepositoryProvider)
          .createReading(reading, photoPaths: _photoPaths);

      // Invalide aussi les autres providers
      ref.invalidate(readingsProvider(null));
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(allMetersCacheFirstProvider);
      ref.invalidate(totalReadingCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              position == null
                  ? 'Показания сохранены без местоположения'
                  : 'Показания успешно сохранены',
            ),
            backgroundColor: MeterSyncTheme.successGreen,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Toujours retourner true pour indiquer un changement
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: MeterSyncTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Affiche un avertissement pour la localisation
  Future<bool> _showLocationWarning() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Предупреждение о местоположении'),
            content: Text(
              _lastKnownPosition != null
                  ? 'Используется последнее известное местоположение от ${_formatTimestamp(_lastKnownPosition!.timestamp)}. Продолжить?'
                  : 'Местоположение недоступно. Сохранить показания без местоположения?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Продолжить'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final meters = ref.watch(metersPagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое показание'),
        actions: [
          if (_isGettingLocation)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_currentPosition != null)
            IconButton(
              icon: Icon(Icons.location_on, color: MeterSyncTheme.successGreen),
              onPressed: _getCurrentLocation,
            )
          else
            IconButton(
              icon: const Icon(Icons.location_off),
              onPressed: _getCurrentLocation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, color: MeterSyncTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Информация о счётчике',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedMeter != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MeterSyncTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedMeter!.meterNumber ?? '-',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (_selectedMeter!.type ?? '').toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.getMeterTypeColor(
                                        _selectedMeter!.type ?? '',
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_selectedMeter!.locationAddress !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedMeter!.locationAddress!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                  if (_selectedMeter!.clientName != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Клиент: ${_selectedMeter!.clientName}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedMeter = null;
                                });
                              },
                              child: const Text('Изменить'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      meters.when(
                        data: (meterList) => DropdownButtonFormField<Meter>(
                          decoration: const InputDecoration(
                            labelText: 'Выберите счётчик',
                            hintText: 'Выберите счётчик',
                          ),
                          initialValue: _selectedMeter,
                          items: meterList.map((meter) {
                            return DropdownMenuItem(
                              value: meter,
                              child: Text(
                                '${meter.meterNumber} - ${meter.type}',
                              ),
                            );
                          }).toList(),
                          onChanged: (meter) {
                            setState(() {
                              _selectedMeter = meter;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Пожалуйста, выберите счётчик';
                            }
                            return null;
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) =>
                            const Text('Ошибка загрузки счётчиков'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: MeterSyncTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Детали показания',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _readingValueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Значение показания',
                        hintText: 'Введите показание счётчика',
                        suffixText: 'кВт·ч',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите значение показания';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Пожалуйста, введите действительное число';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата и время показания',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(_readingDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Заметки (необязательно)',
                        hintText: 'Добавьте наблюдения или комментарии',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: MeterSyncTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Местоположение',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_isOfflineMode) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'АВТОНОМНЫЙ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLocationStatusWidget(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_camera,
                          color: MeterSyncTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Фотографии',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (_photoPaths.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MeterSyncTheme.primaryGreen.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_photoPaths.length}',
                              style: TextStyle(
                                color: MeterSyncTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_photoPaths.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: MeterSyncTheme.textTertiaryLight,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Фотографии не добавлены',
                              style: TextStyle(
                                color: MeterSyncTheme.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photoPaths.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_photoPaths[index]),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _photoPaths.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Сфотографировать'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GradientButton(
                text: 'Сохранить показание',
                icon: Icons.save,
                isLoading: _isLoading,
                onPressed: _submitReading,
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _readingValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

enum LocationStatus { unknown, loading, current, lastKnown, failed }
