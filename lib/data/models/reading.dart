import 'package:uuid/uuid.dart';
import 'dart:convert';

class Reading {
  final String id;
  final String meterId;
  final String userId;
  final double readingValue;
  final DateTime readingDate;
  final String readingType;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? notes;
  final String syncStatus;
  final String? clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> photos; // Local paths initially, URLs after sync

  Reading({
    String? id,
    required this.meterId,
    required this.userId,
    required this.readingValue,
    required this.readingDate,
    this.readingType = 'manual',
    this.deviceId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.notes,
    this.syncStatus = 'pending',
    String? clientId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.photos = const [],
  }) : id = id ?? const Uuid().v4(),
       clientId = clientId ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'],
      meterId: json['meter_id'],
      userId: json['user_id'],
      readingValue: (json['reading_value'] as num).toDouble(),
      readingDate: DateTime.parse(json['reading_date']),
      readingType: json['reading_type'] ?? 'manual',
      deviceId: json['device_id'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      notes: json['notes'],
      syncStatus: json['sync_status'] ?? 'pending',
      clientId: json['client_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      photos: json['photos'] is String
          ? List<String>.from(jsonDecode(json['photos'] ?? '[]'))
          : List<String>.from(json['photos'] ?? []),
    );
  }

  Reading copyWith({
    String? id,
    String? meterId,
    String? userId,
    double? readingValue,
    DateTime? readingDate,
    String? readingType,
    String? deviceId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? notes,
    String? syncStatus,
    String? clientId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? photos,
  }) {
    return Reading(
      id: id ?? this.id,
      meterId: meterId ?? this.meterId,
      userId: userId ?? this.userId,
      readingValue: readingValue ?? this.readingValue,
      readingDate: readingDate ?? this.readingDate,
      readingType: readingType ?? this.readingType,
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // on met à jour par défaut
      photos: photos ?? List<String>.from(this.photos),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meter_id': meterId,
      'user_id': userId,
      'reading_value': readingValue,
      'reading_date': readingDate.toIso8601String(),
      'reading_type': readingType,
      'device_id': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'notes': notes,
      'sync_status': syncStatus,
      'client_id': clientId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'photos': photos, // List for API, encoded for DB
    };
  }
}
