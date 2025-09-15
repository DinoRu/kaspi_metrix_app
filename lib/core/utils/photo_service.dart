import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;

      // Save to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedPath = '${directory.path}/$fileName';

      final savedFile = await File(photo.path).copy(savedPath);
      return savedFile;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> extractExifData(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) return null;

      final exifData = <String, dynamic>{};

      // Extract GPS data
      if (data.containsKey('GPS GPSLatitude') &&
          data.containsKey('GPS GPSLongitude')) {
        exifData['latitude'] = _convertDMSToDD(
          data['GPS GPSLatitude']!.values.toList(),
          data['GPS GPSLatitudeRef']?.printable ?? 'N',
        );
        exifData['longitude'] = _convertDMSToDD(
          data['GPS GPSLongitude']!.values.toList(),
          data['GPS GPSLongitudeRef']?.printable ?? 'E',
        );
      }

      // Extract timestamp
      if (data.containsKey('EXIF DateTimeOriginal')) {
        exifData['taken_at'] = data['EXIF DateTimeOriginal']!.printable;
      }

      // Extract camera info
      if (data.containsKey('Image Make')) {
        exifData['camera_make'] = data['Image Make']!.printable;
      }
      if (data.containsKey('Image Model')) {
        exifData['camera_model'] = data['Image Model']!.printable;
      }

      return exifData;
    } catch (e) {
      print('Error extracting EXIF: $e');
      return null;
    }
  }

  static double _convertDMSToDD(List<dynamic> dms, String ref) {
    if (dms.length != 3) return 0.0;

    final degrees = (dms[0] as Ratio).toDouble();
    final minutes = (dms[1] as Ratio).toDouble();
    final seconds = (dms[2] as Ratio).toDouble();

    double dd = degrees + (minutes / 60) + (seconds / 3600);

    if (ref == 'S' || ref == 'W') {
      dd = -dd;
    }

    return dd;
  }
}
