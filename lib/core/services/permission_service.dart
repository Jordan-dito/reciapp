import 'package:permission_handler/permission_handler.dart';

/// Servicio para solicitar permisos de cámara y galería.
/// Usar antes de abrir image_picker para foto de perfil.
class PermissionService {
  /// Solicita permisos necesarios para usar cámara o galería.
  /// Retorna true si tiene permiso (o se concedió), false si el usuario denegó.
  static Future<bool> requestMediaPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;

    // Solicitar cámara si no está concedida
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        return false;
      }
    }

    // En Android 13+ usar photos; en versiones anteriores storage
    if (!photosStatus.isGranted && !storageStatus.isGranted) {
      final result = await Permission.photos.request();
      if (!result.isGranted) {
        final storageResult = await Permission.storage.request();
        if (!storageResult.isGranted) {
          return false;
        }
      }
    }

    return true;
  }

  /// Verifica si ya tenemos permisos de media
  static Future<bool> hasMediaPermissions() async {
    final camera = await Permission.camera.isGranted;
    final photos = await Permission.photos.isGranted;
    final storage = await Permission.storage.isGranted;
    return camera && (photos || storage);
  }
}
