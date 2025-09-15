// lib/data/models/photo.dart
import 'dart:convert';

import 'package:intl/intl.dart';

class Photo {
  final String id;
  final String readingId;
  final String? localPath;
  final String? remotePath;
  final String uploadStatus;
  final int? fileSizeBytes;
  final String? mimeType;
  final Map<String, dynamic>? exifData;
  final double? latitude;
  final double? longitude;
  final DateTime? takenAt;
  final DateTime? uploadedAt;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.readingId,
    this.localPath,
    this.remotePath,
    this.uploadStatus = 'pending',
    this.fileSizeBytes,
    this.mimeType,
    this.exifData,
    this.latitude,
    this.longitude,
    this.takenAt,
    this.uploadedAt,
    required this.createdAt,
  });

  // -------- API JSON --------
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      readingId: json['reading_id'],
      localPath: json['local_path'] ?? '',
      remotePath: json['remote_path'] ?? json['storage_path'],
      uploadStatus: json['upload_status'] ?? 'pending',
      fileSizeBytes: json['file_size_bytes'],
      mimeType: json['mime_type'],
      exifData: json['exif_data'] is String
          ? jsonDecode(json['exif_data'])
          : json['exif_data'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      takenAt: json['taken_at'] != null
          ? DateTime.parse(json['taken_at'])
          : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reading_id': readingId,
      'local_path': localPath,
      'remote_path': remotePath,
      'upload_status': uploadStatus,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'exif_data': exifData, // API: peut rester map
      'latitude': latitude,
      'longitude': longitude,
      'taken_at': takenAt?.toIso8601String(),
      'uploaded_at': uploadedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // -------- SQLite --------
  factory Photo.fromDbMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as String,
      readingId: map['reading_id'] as String,
      localPath: map['local_path'] as String?,
      remotePath: map['remote_path'] as String?,
      uploadStatus: (map['upload_status'] as String?) ?? 'pending',
      fileSizeBytes: map['file_size_bytes'] as int?,
      mimeType: map['mime_type'] as String?,
      exifData:
          map['exif_data'] != null && (map['exif_data'] as String).isNotEmpty
          ? jsonDecode(map['exif_data'] as String)
          : null,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      takenAt: map['taken_at'] != null
          ? DateTime.parse(map['taken_at'] as String)
          : null,
      uploadedAt: map['uploaded_at'] != null
          ? DateTime.parse(map['uploaded_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'reading_id': readingId,
      'local_path': localPath,
      'remote_path': remotePath,
      'upload_status': uploadStatus,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      // SQLite: stocker en TEXT
      'exif_data': exifData != null ? jsonEncode(exifData) : null,
      'latitude': latitude,
      'longitude': longitude,
      'taken_at': takenAt?.toIso8601String(),
      'uploaded_at': uploadedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ImageModel {
  final String id;
  final String filename;
  final String url;
  final String? cdnUrl;
  final int size;
  final String contentType;
  final DateTime uploadedAt;
  final Map<String, dynamic>? metadata;
  final String? etag;
  final String? fileKey;

  ImageModel({
    required this.id,
    required this.filename,
    required this.url,
    this.cdnUrl,
    required this.size,
    required this.contentType,
    required this.uploadedAt,
    this.metadata,
    this.etag,
    this.fileKey,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      filename: json['filename'],
      url: json['url'],
      cdnUrl: json['cdn_url'],
      size: json['size'],
      contentType: json['content_type'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      metadata: json['metadata'],
      etag: json['etag'],
      fileKey: json['file_key'],
    );
  }

  String get displayUrl => cdnUrl ?? url;

  String get formattedSize {
    final kb = size / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(2)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(uploadedAt);
  }
}
