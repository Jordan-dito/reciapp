# Guía para Consumir el Endpoint de Gráficos por Sucursal (Flutter)

Este documento describe cómo integrar el endpoint de la API PHP para obtener datos de gastos y compras por sucursal en tu aplicación Flutter.

## 1. URL del Endpoint

La URL base del endpoint es:

```
https://[TU_DOMINIO]/tesis%20reciclaje/reportes/api_graficos.php
```

Parámetros GET:

- `action=gastos_compras_por_sucursal` (obligatorio para esta funcionalidad)
- `mes=[NUMERO_MES]` (opcional, ej: `01` para enero)
- `anio=[NUMERO_ANIO]` (opcional, ej: `2026`)

Ejemplos de URL:

- Para obtener datos de todas las sucursales sin filtro de fecha:
  `https://[TU_DOMINIO]/tesis%20reciclaje/reportes/api_graficos.php?action=gastos_compras_por_sucursal`

- Para obtener datos de enero de 2026:
  `https://[TU_DOMINIO]/tesis%20reciclaje/reportes/api_graficos.php?action=gastos_compras_por_sucursal&mes=01&anio=2026`

## 2. Librería HTTP Recomendada

Se recomienda usar el paquete `http` para realizar solicitudes HTTP en Flutter.

Asegúrate de añadirlo a tu `pubspec.yaml`:

```yaml
dependencies:
  http: ^0.13.6
```

## 3. Ejemplo de consumo en Flutter (usando `ApiClient`)

Si usas el `ApiClient` de este proyecto, puedes hacer una llamada GET con `queryParams`:

```dart
final apiClient = ApiClient(baseUrl: AppConfig.baseUrl);

Future<Map<String, dynamic>> getGastosComprasPorSucursal({
  String? mes,
  String? anio,
}) async {
  final queryParams = <String, dynamic>{'action': 'gastos_compras_por_sucursal'};
  if (mes != null) queryParams['mes'] = mes;
  if (anio != null) queryParams['anio'] = anio;

  final response = await apiClient.get(
    '/tesis%20reciclaje/reportes/api_graficos.php',
    queryParams: queryParams,
  );

  if (!response.success) {
    throw Exception(response.error ?? 'Error al obtener datos');
  }

  return response.data ?? {};
}
```

## 4. Formato esperado de respuesta

Se espera que el endpoint devuelva JSON con una estructura similar a:

```json
{
  "success": true,
  "data": [
    {
      "sucursal_id": 1,
      "sucursal_nombre": "Sucursal A",
      "total_gasto": 1500.50,
      "total_compra": 3200.00,
      "total_venta": 4500.00,
      "ganancia": 1300.00
    }
  ],
  "message": "Datos obtenidos"
}
```

## 5. Filtros y paginación

- El endpoint acepta filtros por `mes` y `anio`.
- Si el endpoint soporta paginación, revisa la respuesta para campos como `page`, `per_page`, `total_pages` y ajusta la llamada con parámetros equivalentes.

## 6. Manejo de errores y pruebas

- Verifica `response.success` antes de procesar los datos.
- Añade logs y manejo de excepciones para reconectar o mostrar mensajes al usuario.

## 7. Notas finales

- Asegúrate de reemplazar `[TU_DOMINIO]` por la URL real en producción.
- Si el endpoint requiere autenticación, llama `apiClient.setAuthToken(token)` antes de la petición.
- Si necesitas soporte para content-type o diferentes métodos, adapta la llamada a `post`/`put` según la API.
