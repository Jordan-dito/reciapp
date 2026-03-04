# Iconos de la Aplicación

Para configurar el icono de reciclaje de la aplicación:

## Requisitos

1. **app_icon.png**: Icono principal de 1024x1024 píxeles con fondo transparente o blanco
2. **app_icon_foreground.png**: Icono foreground de 1024x1024 píxeles con fondo transparente (solo el símbolo de reciclaje)

## Pasos

1. Descarga o crea un icono de reciclaje en formato PNG (1024x1024)
2. Coloca el archivo como `app_icon.png` en esta carpeta
3. Crea una versión transparente del icono como `app_icon_foreground.png`
4. Ejecuta el comando:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

## Recursos gratuitos

Puedes descargar iconos de reciclaje gratuitos de:
- [Flaticon](https://www.flaticon.com/search?word=recycling)
- [Iconduck](https://iconduck.com/icons?search=recycling)
- [Freepik](https://www.freepik.com/search?format=search&query=recycling%20icon)

Asegúrate de que los iconos tengan licencia libre para uso comercial.
