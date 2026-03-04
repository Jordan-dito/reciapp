# Guía para Añadir Nuevos Endpoints

Esta estructura está diseñada para que sea fácil añadir nuevos endpoints a la aplicación.

## Estructura Actual

```
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart      # Cliente HTTP base reutilizable
│   │   └── README.md            # Esta guía
│   └── config/
│       └── app_config.dart      # Configuración (URL base, endpoints)
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart  # Ejemplo de datasource remoto
│   │   └── [tu_nuevo_datasource].dart   # Nuevos datasources aquí
│   ├── models/
│   │   └── [tu_modelo].dart     # Modelos de datos
│   └── repositories/
│       └── [tu_repository_impl].dart    # Implementación de repositorios
└── domain/
    ├── entities/
    │   └── [tu_entidad].dart    # Entidades de dominio
    └── repositories/
        └── [tu_repository].dart # Interfaces de repositorios
```

## Pasos para Añadir un Nuevo Endpoint

### 1. Añadir el endpoint en AppConfig

```dart
// lib/core/config/app_config.dart
class AppConfig {
  // ... código existente ...
  
  // Nuevo endpoint
  static const String nuevoEndpoint = '/config/nuevo_endpoint.php';
}
```

### 2. Crear el Modelo (si es necesario)

```dart
// lib/data/models/nuevo_modelo.dart
import '../../domain/entities/nueva_entidad.dart';

class NuevoModelo extends NuevaEntidad {
  const NuevoModelo({
    required super.id,
    // ... otros campos
  });

  factory NuevoModelo.fromJson(Map<String, dynamic> json) {
    return NuevoModelo(
      id: json['id'],
      // ... mapear otros campos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // ... otros campos
    };
  }
}
```

### 3. Crear el Datasource Remoto

```dart
// lib/data/datasources/nuevo_remote_datasource.dart
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/nuevo_modelo.dart';

class NuevoRemoteDataSource {
  final ApiClient apiClient;

  NuevoRemoteDataSource({required this.apiClient});

  Future<NuevoModelo> obtenerDatos(int id) async {
    final response = await apiClient.get(
      '${AppConfig.nuevoEndpoint}/$id',
    );

    if (response.success && response.data != null) {
      return NuevoModelo.fromJson(response.data!);
    } else {
      throw Exception(response.error ?? 'Error al obtener datos');
    }
  }

  Future<NuevoModelo> crearDatos(Map<String, dynamic> datos) async {
    final response = await apiClient.post(
      AppConfig.nuevoEndpoint,
      body: datos,
    );

    if (response.success && response.data != null) {
      return NuevoModelo.fromJson(response.data!);
    } else {
      throw Exception(response.error ?? 'Error al crear datos');
    }
  }
}
```

### 4. Crear/Actualizar el Repositorio

```dart
// lib/data/repositories/nuevo_repository_impl.dart
import '../../domain/entities/nueva_entidad.dart';
import '../../domain/repositories/nuevo_repository.dart';
import '../datasources/nuevo_remote_datasource.dart';

class NuevoRepositoryImpl implements NuevoRepository {
  final NuevoRemoteDataSource remoteDataSource;

  NuevoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<NuevaEntidad> obtenerDatos(int id) async {
    return await remoteDataSource.obtenerDatos(id);
  }
}
```

### 5. Inyectar en main.dart

```dart
// lib/main.dart
MultiRepositoryProvider(
  providers: [
    // ... providers existentes ...
    
    // Nuevo datasource
    RepositoryProvider<NuevoRemoteDataSource>(
      create: (context) => NuevoRemoteDataSource(
        apiClient: context.read<ApiClient>(),
      ),
    ),
    
    // Nuevo repositorio
    RepositoryProvider<NuevoRepositoryImpl>(
      create: (context) => NuevoRepositoryImpl(
        remoteDataSource: context.read<NuevoRemoteDataSource>(),
      ),
    ),
  ],
  // ...
)
```

## Métodos Disponibles en ApiClient

El `ApiClient` proporciona los siguientes métodos:

- `get(endpoint, {headers, queryParams})` - Petición GET
- `post(endpoint, {headers, body, bodyJson})` - Petición POST
- `put(endpoint, {headers, body, bodyJson})` - Petición PUT
- `delete(endpoint, {headers})` - Petición DELETE
- `setAuthToken(token)` - Configurar token de autenticación
- `removeAuthToken()` - Eliminar token de autenticación

## Ejemplo Completo: Endpoint de Reportes

```dart
// 1. AppConfig
static const String reportsEndpoint = '/config/reports.php';

// 2. Datasource
class ReportsRemoteDataSource {
  final ApiClient apiClient;
  
  ReportsRemoteDataSource({required this.apiClient});
  
  Future<List<ReportModel>> getReports() async {
    final response = await apiClient.get(AppConfig.reportsEndpoint);
    
    if (response.success && response.data != null) {
      final List<dynamic> reportsJson = response.data!['reports'] ?? [];
      return reportsJson.map((json) => ReportModel.fromJson(json)).toList();
    } else {
      throw Exception(response.error ?? 'Error al obtener reportes');
    }
  }
}
```

## Notas Importantes

1. **URL Base**: Asegúrate de configurar la URL correcta en `AppConfig.baseUrl`
   - Para desarrollo local Android: `http://10.0.2.2`
   - Para servidor remoto: `http://tu-servidor.com` o `https://tu-servidor.com`

2. **Manejo de Errores**: Siempre maneja los errores apropiadamente en los datasources

3. **Tokens**: Si tu backend usa tokens JWT, usa `apiClient.setAuthToken(token)` después del login

4. **Headers Personalizados**: Puedes pasar headers adicionales en cada petición si es necesario

