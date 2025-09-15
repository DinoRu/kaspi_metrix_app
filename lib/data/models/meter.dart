// =====================================
// lib/data/models/meter.dart
// =====================================
import 'dart:convert';

class Meter {
  final String id;
  final String meterIdCode;
  final String? meterNumber;
  final String? type;
  final String? locationAddress;
  final String? clientName;
  final DateTime? lastReadingDate;
  final String status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  Meter({
    required this.id,
    required this.meterIdCode,
    this.meterNumber,
    this.type,
    this.locationAddress,
    this.clientName,
    this.lastReadingDate,
    this.status = 'active',
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  factory Meter.fromJson(Map<String, dynamic> json) {
    return Meter(
      id: json['id'],
      meterIdCode: json["meter_id_code"],
      meterNumber: json['meter_number'],
      type: json['type'],
      locationAddress: json['location_address'],
      clientName: json['client_name'],
      lastReadingDate: json['last_reading_date'] != null
          ? DateTime.parse(json['last_reading_date'])
          : null,
      status: json['status'] ?? 'active',
      metadata:
          (json['meter_metadata'] is String
              ? jsonDecode(json['meter_metadata'] as String)
              : json['meter_metadata'] as Map<String, dynamic>?) ??
          {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      syncStatus: json['sync_status'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meter_id_code': meterIdCode,
      'meter_number': meterNumber,
      'type': type,
      'location_address': locationAddress,
      'client_name': clientName,
      'last_reading_date': lastReadingDate?.toIso8601String(),
      'status': status,
      'meter_metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }
}
