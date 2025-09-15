import 'dart:convert';
import 'package:metrix/config/constants.dart';
import 'package:metrix/core/network/api_client.dart';
import 'package:metrix/core/database/database_helper.dart';
import 'package:metrix/core/network/api_service.dart';
import 'package:metrix/data/models/reading.dart';
import 'package:metrix/core/sync/outbox_manager.dart';
import 'package:sqflite/sqflite.dart';

class ReadingRepository {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final OutboxManager _outboxManager = OutboxManager();

  static const String baseUrl = 'http://10.0.2.2:8000';

  ReadingRepository(this._apiClient);
  Future<Reading> createReading(
    Reading reading, {
    List<String>? photoPaths,
  }) async {
    final db = await _dbHelper.database;
    late Reading result;

    await db.transaction<void>((txn) async {
      final map = reading.toJson();
      map['photos'] = jsonEncode(photoPaths ?? reading.photos);

      await txn.insert('readings', map);
      print('✅ Reading inserted with meter_id: ${reading.meterId}'); // DEBUG

      await txn.update(
        'meters',
        {
          'last_reading_date': reading.readingDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [reading.meterId],
      );

      print('✅ Meter updated with id: ${reading.meterId}'); // DEBUG

      result = reading.copyWith(
        photos: photoPaths ?? reading.photos,
      ); // Assignment here
    });

    await _outboxManager.addToOutbox(
      entityType: 'reading',
      entityId: reading.id,
      operation: 'create',
      payload: reading.toJson(),
    );

    return result;
  }

  Future<List<Reading>> getReadings({String? meterId}) async {
    final db = await _dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (meterId != null) {
      whereClause = 'meter_id = ?';
      whereArgs = [meterId];
    }

    final maps = await db.query(
      'readings',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'reading_date DESC',
    );

    return maps.map((m) => Reading.fromJson(m)).toList();
  }

  Future<int> getPendingSyncCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM readings WHERE sync_status = ?',
      ['pending'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> syncReadings() async {
    await _outboxManager.processPending((item) async {
      final entityType = item['entity_type'] as String;
      final payload =
          jsonDecode(item['payload'] as String) as Map<String, dynamic>;

      if (entityType == 'reading') {
        final localReadingId = payload['id'] as String;
        final db = await _dbHelper.database;
        final reading = Reading.fromJson(payload);

        if (reading.photos.length < 2) {
          throw Exception('At least 2 photos required for sync');
        }

        // Upload photos, collect URLs
        final List<String> urls = [];
        for (final localPath in reading.photos) {
          // final url = await _uploadPhoto(localPath, localReadingId);
          final url = await ApiService.uploadPhoto(localPath, localReadingId);
          urls.add(url);
        }

        // Update payload with URLs
        payload['photos'] = urls;

        // Post reading
        final response = await _apiClient.dio.post(
          ApiConstants.readings,
          data: payload,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final serverId = response.data['id'] as String;

          await db.update(
            'readings',
            {
              'id': serverId,
              'sync_status': 'synced',
              'updated_at': DateTime.now().toIso8601String(),
              'photos': jsonEncode(urls), // Store URLs
            },
            where: 'id = ?',
            whereArgs: [localReadingId],
          );

          print('Synced reading $serverId with ${urls.length} photos');
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
      }
    }, batchSize: 10);
  }

  /// Counts readings made today (based on reading_date)
  Future<int> getTodayReadingsCount() async {
    final db = await _dbHelper.database;

    // Get start of today (midnight)
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final result = await db.rawQuery(
      'SELECT COUNT (*) as count FROM readings WHERE date(reading_date) = date(?)',
      [startOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalReadingsCount() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('SELECT COUNT(*) as count FROM readings');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
