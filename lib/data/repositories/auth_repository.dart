import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:metrix/config/constants.dart';
import 'package:metrix/core/database/database_helper.dart';
import 'package:metrix/core/network/api_client.dart';
import 'package:metrix/data/models/user.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AuthRepository(this._apiClient);

  Future<User> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      final userData = response.data['user'];
      final user = User.fromJson({
        ...userData,
        'access_token': response.data['access_token'],
        'refresh_token': response.data['refresh_token'],
      });

      // Save tokens
      await _storage.write(
        key: 'access_token',
        value: response.data['access_token'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: response.data['refresh_token'],
      );
      await _storage.write(key: 'user_id', value: user.id);

      // Save user to local DB
      final db = await _dbHelper.database;
      await db.insert(
        'users',
        user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    await _dbHelper.clearAllData();
    // Clear local database if needed
  }

  Future<User?> getCurrentUser() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) return null;

      final db = await _dbHelper.database;
      final maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (maps.isEmpty) return null;

      return User.fromJson(maps.first);
    } catch (e) {
      return null;
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.connectionError:
          return 'No internet connection.';
        default:
          if (error.response != null) {
            return error.response!.data['detail'] ?? 'An error occurred';
          }
          return 'An unexpected error occurred';
      }
    }
    return error.toString();
  }
}
