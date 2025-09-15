// =====================================
// lib/data/repositories/meter_repository.dart
// =====================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:metrix/config/constants.dart';
import 'package:metrix/core/database/database_helper.dart';
import 'package:metrix/core/network/api_client.dart';
import 'package:metrix/data/models/meter.dart';
import 'package:sqflite/sqflite.dart';

class MeterRepository {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  MeterRepository(this._apiClient);

  // -------- API PAGES --------
  Future<List<Meter>> fetchApiPage({
    required int skip,
    required int limit,
  }) async {
    // Implemente ici le même systeme que le premier
    // Verifie la base de donnée locale
    final res = await _apiClient.dio.get(
      ApiConstants.meters,
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final list = (res.data['data'] as List)
        .map((j) => Meter.fromJson(j))
        .toList();

    return list;
  }

  Future<List<Meter>> getAllLocalMeters() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
    SELECT m.*
    FROM meters m
    WHERE NOT EXISTS (
      SELECT 1 FROM readings r WHERE r.meter_id = m.id
    )
    ORDER BY m.created_at DESC
  ''');
    final list = result.map((j) => Meter.fromJson(j)).toList();
    return list;
  }

  /// Retourne tous les meters en mode cache-first
  Future<List<Meter>> getAllMeters({int pageSize = 500}) async {
    final db = await _dbHelper.database;

    // 1. Vérifie si la DB locale a déjà des données
    final localData = await db.rawQuery('''
    SELECT m.*
    FROM meters m
    WHERE NOT EXISTS (
      SELECT 1 FROM readings r WHERE r.meter_id = m.id
    )
    ORDER BY m.created_at DESC
  ''');
    if (localData.isNotEmpty) {
      return localData.map((m) => Meter.fromJson(m)).toList();
    }

    // 2. Sinon → fetch depuis API + cache
    int skip = 0;
    List<Meter> allFetched = [];
    while (true) {
      final page = await fetchApiPage(skip: skip, limit: pageSize);
      if (page.isEmpty) break;

      // insérer dans DB locale
      final batch = db.batch();
      for (final m in page) {
        batch.insert(
          'meters',
          m.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      allFetched.addAll(page);

      if (page.length < pageSize) break;
      skip += pageSize;
    }

    return allFetched;
  }

  // -------- SYNC ALL --------
  Future<int> syncAll({int pageSize = 500, bool wipeBefore = false}) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return 0;

    final db = await _dbHelper.database;
    if (wipeBefore) {
      await db.delete('meters');
    }

    int skip = 0;
    int insertedTotal = 0;
    while (true) {
      final page = await fetchApiPage(skip: skip, limit: pageSize);
      if (page.isEmpty) break;

      final batch = db.batch();
      for (final m in page) {
        batch.insert(
          'meters',
          m.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      insertedTotal += page.length;
      if (page.length < pageSize) break;
      skip += pageSize;
    }
    return insertedTotal;
  }

  // -------- READ LOCAL PAGES --------
  Future<List<Meter>> getLocalPage({
    required int offset,
    required int limit,
    bool unreadOnly = false,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
    SELECT m.*
    FROM meters m
    WHERE NOT EXISTS (
      SELECT 1 FROM readings r WHERE r.meter_id = m.id
    )
    ORDER BY m.created_at DESC
    LIMIT ? OFFSET ?
  ''',
      [limit, offset],
    );
    return maps.map((m) => Meter.fromJson(m)).toList();
  }

  Future<int> countLocal() async {
    final db = await _dbHelper.database;
    final res =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM meters'),
        ) ??
        0;
    return res;
  }

  // -------- RECHERCHE LOCALE --------
  Future<List<Meter>> searchLocal(
    String query, {
    required int offset,
    required int limit,
    bool unreadOnly = false,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'meters',
      where: unreadOnly
          ? 'last_reading_date IS NULL AND (meter_number LIKE ? OR client_name LIKE ?)'
          : 'meter_number LIKE ? OR client_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Meter.fromJson(m)).toList();
  }

  // -------- RECHERCHE LOCALE PAGINÉE --------
  Future<List<Meter>> searchLocalPage(
    String query, {
    required int offset,
    required int limit,
    bool unreadOnly = false,
  }) async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      'meters',
      where: unreadOnly
          ? 'last_reading_date IS NULL AND (meter_number LIKE ? OR client_name LIKE ?)'
          : 'meter_number LIKE ? OR client_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Meter.fromJson(m)).toList();
  }
}
