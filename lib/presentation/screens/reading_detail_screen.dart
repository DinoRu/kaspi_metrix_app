import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:metrix/data/models/reading.dart';

class ReadingDetailScreen extends ConsumerWidget {
  final Reading reading;

  const ReadingDetailScreen({super.key, required this.reading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMMM yyyy', 'ru');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция редактирования скоро появится'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Редактировать',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Main Value - Large and Centered
              Center(
                child: Column(
                  children: [
                    Text(
                      reading.readingValue.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'кВт·ч',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[600],
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sync Status - Minimal Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: reading.syncStatus == 'synced'
                              ? Colors.green
                              : Colors.orange,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reading.syncStatus == 'synced'
                            ? 'СИНХРОНИЗИРОВАНО'
                            : 'В ОЖИДАНИИ',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w500,
                          color: reading.syncStatus == 'synced'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Date and Time - Clean Section
              _buildMinimalSection(
                'ДАТА И ВРЕМЯ',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(reading.readingDate),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      'в ${timeFormat.format(reading.readingDate)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Reading Type
              _buildMinimalSection(
                'ТИП',
                Text(
                  reading.readingType == 'manual'
                      ? 'Ручной ввод'
                      : 'Сканировано',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

              // Location - If Available
              if (reading.latitude != null && reading.longitude != null)
                _buildMinimalSection(
                  'МЕСТОПОЛОЖЕНИЕ',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reading.latitude!.toStringAsFixed(6)}, ${reading.longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (reading.accuracyMeters != null)
                        Text(
                          'Точность: ±${reading.accuracyMeters!.toStringAsFixed(0)} метров',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.8,
                          ),
                        ),
                    ],
                  ),
                ),

              // Notes - If Available
              if (reading.notes != null && reading.notes!.isNotEmpty)
                _buildMinimalSection(
                  'ЗАМЕТКИ',
                  Text(
                    reading.notes!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),

              // Photos - Minimal Grid
              if (reading.photos.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'ФОТОГРАФИИ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: reading.photos.length,
                  itemBuilder: (context, index) {
                    final photo = reading.photos[index];
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(context, photo),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: _buildPhotoWidget(photo),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 48),

              // Divider
              Container(height: 1, color: Colors.grey[200]),

              const SizedBox(height: 32),

              // Metadata - Very Minimal
              Text(
                'ДЕТАЛИ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              _buildMinimalDetail(
                'ИДЕНТИФИКАТОР',
                reading.id.substring(0, 8).toUpperCase(),
              ),
              _buildMinimalDetail(
                'СЧЁТЧИК',
                reading.meterId.substring(0, 8).toUpperCase(),
              ),
              _buildMinimalDetail(
                'СОЗДАНО',
                DateFormat(
                  'd MMM yyyy • HH:mm',
                  'ru',
                ).format(reading.createdAt),
              ),
              _buildMinimalDetail(
                'ОБНОВЛЕНО',
                DateFormat(
                  'd MMM yyyy • HH:mm',
                  'ru',
                ).format(reading.updatedAt),
              ),
              if (reading.deviceId != null)
                _buildMinimalDetail('УСТРОЙСТВО', reading.deviceId!),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalSection(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildMinimalDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(String photoPath) {
    if (photoPath.startsWith('http')) {
      return Image.network(
        photoPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: Icon(
              Icons.image_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: Icon(
              Icons.image_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
          );
        },
      );
    }
  }

  void _showFullScreenImage(BuildContext context, String photoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPhotoWidget(photoPath),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
