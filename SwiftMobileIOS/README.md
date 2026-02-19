# SwiftMobileIOS

Estructura base SwiftUI para consumir el backend con sesión por cookie.

## Configuración rápida
1. Abrir el proyecto en Xcode y agregar estos archivos a tu target iOS.
2. Cambiar la URL en `AppConfig.baseURL`.
3. Ejecutar.

## Nota
La sesión se guarda con cookie `sessionId` usando `HTTPCookieStorage` y se persiste en `UserDefaults`.
