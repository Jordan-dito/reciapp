import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio para verificar el estado de conectividad de la red
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Verifica si hay conexión a internet
  /// Retorna true si hay conexión (WiFi o móvil), false si no hay conexión
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Verificar si hay algún tipo de conexión
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // Si hay un error al verificar, asumir que no hay conexión
      return false;
    }
  }

  /// Obtiene el tipo de conexión actual
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  /// Stream que escucha cambios en la conectividad
  Stream<ConnectivityResult> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
}
