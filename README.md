# Recicladora App

Aplicación móvil para gestión de recicladora desarrollada con Flutter siguiendo principios de Clean Architecture y Clean Code.

## 🎯 Características

- ✅ **Arquitectura Limpia** (Clean Architecture)
  - Separación en capas: Domain, Data, Presentation
  - Gestión de estado con BLoC Pattern
  - Repositorios y casos de uso bien definidos

- 🔐 **Autenticación**
  - Pantalla de login con validación
  - Gestión de sesión persistente
  - Navegación basada en estado de autenticación

- 📊 **Dashboard**
  - Pantalla de inicio con estadísticas
  - Tarjetas de resumen de métricas
  - Menú de navegación intuitivo

- 📈 **Reportes**
  - Gráficos de barras (materiales reciclados)
  - Gráficos de líneas (tendencia de ingresos)
  - Gráficos circulares (distribución de materiales)
  - Visualización de estadísticas completas

## 🏗️ Estructura del Proyecto

```
lib/
├── core/                    # Configuraciones globales
│   ├── config/             # Configuración de la app
│   ├── routes/             # Configuración de rutas
│   └── theme/              # Tema y estilos
├── data/                   # Capa de datos
│   ├── datasources/        # Fuentes de datos (local, remoto)
│   ├── models/             # Modelos de datos
│   └── repositories/       # Implementación de repositorios
├── domain/                 # Capa de dominio
│   ├── entities/           # Entidades de negocio
│   └── repositories/       # Contratos de repositorios
└── presentation/           # Capa de presentación
    ├── bloc/               # Gestión de estado (BLoC)
    └── screens/            # Pantallas de la aplicación
```

## 🚀 Instalación

1. Asegúrate de tener Flutter instalado en tu sistema
   ```bash
   flutter --version
   ```

2. Clona o descarga el proyecto

3. Instala las dependencias
   ```bash
   flutter pub get
   ```

4. Ejecuta la aplicación
   ```bash
   flutter run
   ```

## 📦 Dependencias Principales

- **flutter_bloc**: Gestión de estado reactiva
- **go_router**: Navegación declarativa
- **shared_preferences**: Almacenamiento local
- **fl_chart**: Gráficos y visualización de datos
- **equatable**: Comparación de objetos

## 🎨 Tema y Diseño

La aplicación utiliza un tema personalizado con colores relacionados con reciclaje:
- Verde primario (#2E7D32)
- Verde secundario (#4CAF50)
- Verde acento (#81C784)
- Fondo verde claro (#E8F5E9)

## 🔑 Login de Prueba

Para probar la aplicación, puedes usar cualquier usuario y contraseña (mínimo 4 caracteres). El login está simulado y guardará la sesión localmente.

## 📱 Pantallas

### Splash Screen
Pantalla de bienvenida que verifica el estado de autenticación.

### Login Screen
Pantalla de inicio de sesión con validación de formularios y manejo de errores.

### Home Screen
Dashboard principal con:
- Tarjeta de bienvenida
- Estadísticas rápidas (materiales, ingresos, recolecciones, crecimiento)
- Menú de navegación a diferentes secciones

### Reports Screen
Pantalla de reportes con:
- Resumen del mes
- Gráfico de barras de materiales reciclados
- Gráfico de líneas de tendencia de ingresos
- Gráfico circular de distribución de materiales

## 🧹 Clean Code Practices

- ✅ Separación de responsabilidades
- ✅ Principios SOLID
- ✅ DRY (Don't Repeat Yourself)
- ✅ Nombres descriptivos
- ✅ Funciones pequeñas y enfocadas
- ✅ Comentarios donde son necesarios
- ✅ Manejo de errores adecuado

## 📝 Notas

- El proyecto está configurado para desarrollo inicial
- La autenticación está simulada para propósitos de demostración
- Los datos de reportes son de ejemplo y se pueden conectar a un backend real

## 🤝 Contribuciones

Este es un proyecto de demostración. Siéntete libre de modificarlo según tus necesidades.

## 📄 Licencia

Este proyecto está disponible para uso educativo y de demostración.

# reciapp
