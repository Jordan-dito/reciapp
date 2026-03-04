import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar la foto de perfil del usuario
/// Guarda la foto en la caché del dispositivo
class ProfileImageService {
  static const String _profileImageKey = 'profile_image_path';

  /// Guarda la ruta de la imagen de perfil
  Future<void> saveProfileImagePath(String imagePath, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_profileImageKey}_$userId', imagePath);
  }

  /// Obtiene la ruta de la imagen de perfil guardada
  Future<String?> getProfileImagePath(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_profileImageKey}_$userId');
  }

  /// Guarda la imagen de perfil en la caché del dispositivo
  /// Retorna la ruta donde se guardó la imagen
  Future<String> saveProfileImage(File imageFile, int userId) async {
    try {
      // Obtener el directorio de caché
      final cacheDir = await getTemporaryDirectory();
      
      // Crear el directorio de imágenes de perfil si no existe
      final profileDir = Directory('${cacheDir.path}/profile_images');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      // Crear el nombre del archivo usando el ID del usuario
      final fileName = 'profile_$userId.jpg';
      final savedImage = File('${profileDir.path}/$fileName');

      // Copiar la imagen al directorio de caché
      await imageFile.copy(savedImage.path);

      // Guardar la ruta en SharedPreferences
      await saveProfileImagePath(savedImage.path, userId);

      return savedImage.path;
    } catch (e) {
      throw Exception('Error al guardar la imagen: $e');
    }
  }

  /// Carga la imagen de perfil desde la caché
  /// Retorna un File si existe, null si no hay imagen guardada
  Future<File?> loadProfileImage(int userId) async {
    try {
      final imagePath = await getProfileImagePath(userId);
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          return file;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Elimina la imagen de perfil guardada
  Future<void> deleteProfileImage(int userId) async {
    try {
      final imagePath = await getProfileImagePath(userId);
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_profileImageKey}_$userId');
    } catch (e) {
      // Ignorar errores al eliminar
    }
  }
}

