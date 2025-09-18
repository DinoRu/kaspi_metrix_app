import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:metrix/config/constants.dart';
import 'package:metrix/data/models/photo.dart';
import 'package:mime/mime.dart';

class ApiService {
  static const String baseUrl = 'http://45.67.59.246';
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  static Future<ImageModel?> uploadImage(File imageFile) async {
    try {
      // Étape 1: Déterminer le type MIME et le nom du fichier
      String filename = imageFile.path.split('/').last;
      String? mimeType = lookupMimeType(imageFile.path);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        String extension = filename.split('.').last.toLowerCase();
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            throw Exception('Type de fichier non supporté: $extension');
        }
      }

      // Étape 2: Obtenir l'URL pré-signée depuis l'API
      final presignedResponse = await _dio.post(
        ApiConstants.photosPresignedUrl,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {'filename': filename, 'content_type': mimeType},
      );

      if (presignedResponse.statusCode != 200) {
        throw Exception(
          'Erreur obtention URL pré-signée: ${presignedResponse.data}',
        );
      }

      final presignedData = presignedResponse.data;
      String uploadUrl = presignedData['upload_url'];
      String fileKey = presignedData['file_key'];
      String fileId = presignedData['file_id'];
      Map<String, String> uploadHeaders = Map<String, String>.from(
        presignedData['upload_headers'],
      );

      // Étape 3: Uploader le fichier directement vers S3 via PUT
      final bytes = await imageFile.readAsBytes();
      final uploadResponse = await _dio.put(
        uploadUrl,
        options: Options(
          headers:
              uploadHeaders, // Inclut tous les headers (Content-Type, x-amz-meta-*)
        ),
        data: bytes,
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception(
          'Erreur upload vers S3: ${uploadResponse.statusCode} - ${uploadResponse.data}',
        );
      }

      // Étape 4: Confirmer l'upload auprès de l'API
      final confirmResponse = await _dio.post(
        ApiConstants.photosConfirm,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {'file_key': fileKey, 'file_id': fileId},
      );

      if (confirmResponse.statusCode == 200) {
        return ImageModel.fromJson(confirmResponse.data);
      } else {
        throw Exception('Erreur confirmation upload: ${confirmResponse.data}');
      }
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
      return null;
    }
  }

  static Future<List<ImageModel>> getImages({int limit = 100}) async {
    try {
      final response = await _dio.get(
        '/api/images',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        return (jsonData['images'] as List)
            .map((item) => ImageModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Erreur récupération images: ${response.data}');
      }
    } catch (e) {
      print('Erreur lors de la récupération: $e');
      return [];
    }
  }

  static Future<bool> deleteImage(String imageId) async {
    try {
      final response = await _dio.delete('/api/images/$imageId');
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  static Future<String> uploadPhoto(String localPath, String readingId) async {
    final file = File(localPath);
    String filename = file.path.split('/').last;
    String? mimeType = lookupMimeType(file.path);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      String extension = filename.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          throw Exception('Type de fichier non supporté: $extension');
      }
    }

    log('Uploading file: $localPath');
    log('Filename: $filename');
    log('Content-Type: $mimeType');

    try {
      final presignedResponse = await _dio.post(
        ApiConstants.photosPresignedUrl,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {'filename': filename, 'content_type': mimeType},
      );

      log('Presigned URL response: ${presignedResponse.data}');

      if (presignedResponse.statusCode != 200) {
        throw Exception(
          'Erreur obtention URL pré-signée: ${presignedResponse.data}',
        );
      }

      final presignedData = presignedResponse.data;
      String uploadUrl = presignedData['upload_url'];
      String fileKey = presignedData['file_key'];
      String fileId = presignedData['file_id'];
      Map<String, String> uploadHeaders = Map<String, String>.from(
        presignedData['upload_headers'],
      );

      log('Upload URL: $uploadUrl');
      log('Headers: $uploadHeaders');

      final bytes = await file.readAsBytes();
      log('File size: ${bytes.length} bytes');

      final uploadResponse = await _dio.put(
        uploadUrl,
        options: Options(
          headers: uploadHeaders,
          validateStatus: (status) => true,
        ),
        data: bytes,
      );

      log(
        'Upload response: ${uploadResponse.statusCode} ${uploadResponse.data}',
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception(
          'Erreur upload vers S3: ${uploadResponse.statusCode} - ${uploadResponse.data}',
        );
      }

      final confirmResponse = await _dio.post(
        ApiConstants.photosConfirm,
        data: {'file_id': fileId, 'file_key': fileKey},
      );

      if (confirmResponse.statusCode == 200) {
        final data = ImageModel.fromJson(confirmResponse.data);
        await file.delete();
        final publicUrl = data.url;
        log('Photo uploaded successfully: $publicUrl');
        return publicUrl;
      } else {
        throw Exception('Erreur confirmation upload: ${confirmResponse.data}');
      }
    } catch (e) {
      log('Error uploading photo $localPath: $e');
      rethrow;
    }
  }
}
