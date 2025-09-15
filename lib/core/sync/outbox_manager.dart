import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:metrix/core/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class OutboxManager {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 5);

  Future<void> addToOutbox({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('outbox', {
      'id': const Uuid().v4(),
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'retry_count': 0,
      'max_retries': _maxRetries,
      'status': 'pending',
      'scheduled_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      // 'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    print('Added to outbox: $entityId ($entityType)');
  }

  Future<void> processPending(
    Future<void> Function(Map<String, dynamic>) processor, {
    int batchSize = 10,
  }) async {
    final db = await _dbHelper.database;
    final items = await db.query(
      'outbox',
      where: 'status = ? AND retry_count < max_retries',
      whereArgs: ['pending'],
      limit: batchSize,
    );

    for (final item in items) {
      try {
        await processor(item);
        await db.update(
          'outbox',
          {
            'status': 'completed',
            'processed_at': DateTime.now().toIso8601String(),
            'error_message': null,
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        print('Outbox item completed: ${item['id']}');
      } catch (e) {
        final retryCount = (item['retry_count'] as int) + 1;
        if (retryCount >= _maxRetries) {
          await db.update(
            'outbox',
            {'status': 'failed', 'error_message': e.toString()},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
          print('Outbox item failed after max retries: ${item['id']}');
        } else {
          final delay = _baseDelay * (1 << retryCount);
          await db.update(
            'outbox',
            {
              'retry_count': retryCount,
              'scheduled_at': DateTime.now().add(delay).toIso8601String(),
              'error_message': e.toString(),
              // 'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item['id']],
          );
          print(
            'Outbox item retry scheduled: ${item['id']} ($retryCount/$_maxRetries)',
          );
        }
      }
    }
  }

  Future<void> removeFromOutbox(String entityId) async {
    final db = await _dbHelper.database;
    await db.delete('outbox', where: 'entity_id = ?', whereArgs: [entityId]);
    print('Removed from outbox: $entityId');
  }
}
