import 'dart:io';
import 'package:dio/dio.dart';
import 'package:metrix/config/constants.dart';
import 'package:metrix/core/network/api_client.dart';
import 'package:metrix/core/database/database_helper.dart';
import 'package:metrix/data/models/photo.dart';

class PhotoRepository {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  PhotoRepository(this._apiClient);

  /// Request presigned URL
  Future<Map<String, dynamic>> requestPresignedUrl({
    required String readingId,
    required String fileExtension,
    int? fileSizeBytes,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        ApiConstants.photosPresignedUrl, // Corrected endpoint
        data: {
          'reading_id': readingId,
          'file_extension': fileExtension,
          'file_size_bytes': fileSizeBytes,
        },
      );
      print('Presigned URL response: ${res.data}');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      print('Error requesting presigned URL: $e');
      rethrow;
    }
  }

  /// Upload to presigned URL
  Future<void> uploadFileToPresignedUrl({
    required String uploadUrl,
    required File file,
    String? mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    try {
      final response = await dio.put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader:
                mimeType ?? 'application/octet-stream',
          },
        ),
        onSendProgress: onProgress,
      );
      print('Upload response: ${response.statusCode}');
    } catch (e) {
      print('Error uploading to presigned URL: $e');
      rethrow;
    }
  }

  /// Complete upload
  Future<void> completeUpload({
    required String photoId,
    required String storageKey,
    int? fileSizeBytes,
    Map<String, dynamic>? exifData,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.photosConfirm,
        data: {
          'photo_id': photoId,
          'storage_key': storageKey,
          'file_size_bytes': fileSizeBytes,
          'exif_data': exifData,
        },
      );
      print('Complete upload response: ${response.statusCode}');
    } catch (e) {
      print('Error completing upload: $e');
      rethrow;
    }
  }

  /// Process local photo upload
  // data/repositories/photo_repository.dart
  Future<void> processLocalPhotoUpload(Photo photoLocal) async {
    final db = await _dbHelper.database;
    final file = File(photoLocal.localPath!);
    if (!await file.exists()) {
      print('Photo file does not exist: ${photoLocal.localPath}');
      await db.update(
        'photos',
        {'upload_status': 'failed', 'error_message': 'File not found'},
        where: 'id = ?',
        whereArgs: [photoLocal.id],
      );
      return;
    }
    final fileSize = await file.length();
    final ext = photoLocal.localPath!.split('.').last.toLowerCase();

    // Request presigned URL
    final presign = await requestPresignedUrl(
      readingId: photoLocal.readingId,
      fileExtension: ext,
      fileSizeBytes: fileSize,
    );

    final uploadUrl = presign['upload_url'] as String;
    final storageKey = presign['storage_key'] as String;
    final photoId = presign['photo_id'] as String;

    // Update local photo with server photo_id and storage_key
    await db.update(
      'photos',
      {
        'id': photoId, // Use server-generated photo_id
        'storage_key': storageKey,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [photoLocal.id],
    );

    // Upload to S3
    await uploadFileToPresignedUrl(
      uploadUrl: uploadUrl,
      file: file,
      mimeType: photoLocal.mimeType ?? 'image/$ext',
    );

    // Complete upload and get download_url
    final completeResponse = await _apiClient.dio.post(
      ApiConstants.photosConfirm,
      data: {
        'photo_id': photoId,
        'storage_key': storageKey,
        'file_size_bytes': fileSize,
        'exif_data': photoLocal.exifData,
      },
    );
    final downloadUrl = completeResponse.data['download_url'] as String?;

    // Update local database with download_url
    await db.update(
      'photos',
      {
        'remote_path': downloadUrl, // Set from /complete response
        'upload_status': 'synced',
        'uploaded_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [photoId],
    );
    print('Photo upload completed: $photoId');
  }
}
