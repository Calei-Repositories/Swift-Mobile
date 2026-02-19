# Fuentes Saira para Calei iOS

## Instrucciones de Instalación

Para que la fuente Saira funcione correctamente en la app, debes:

### 1. Descargar las fuentes

Descarga la familia de fuentes Saira desde:
- **Google Fonts**: https://fonts.google.com/specimen/Saira

### 2. Agregar los archivos

Coloca los siguientes archivos .ttf en esta carpeta:
- `Saira-Regular.ttf`
- `Saira-Medium.ttf`
- `Saira-SemiBold.ttf`
- `Saira-Bold.ttf`

### 3. Agregar al proyecto en Xcode

1. Abre el proyecto en Xcode
2. Haz clic derecho en la carpeta `Fonts` en el navegador de proyectos
3. Selecciona "Add Files to 'SwiftMobileIOS'..."
4. Selecciona todos los archivos .ttf
5. **Importante**: Marca "Copy items if needed" y asegúrate de que el target `SwiftMobileIOS` esté seleccionado

### 4. Verificar Info.plist

El Info.plist ya está configurado con las fuentes. Verifica que contenga:

```xml
<key>UIAppFonts</key>
<array>
    <string>Saira-Regular.ttf</string>
    <string>Saira-Medium.ttf</string>
    <string>Saira-SemiBold.ttf</string>
    <string>Saira-Bold.ttf</string>
</array>
```

### 5. Verificar en código

Para verificar que las fuentes están disponibles, puedes usar este snippet en cualquier View:

```swift
.onAppear {
    for family in UIFont.familyNames.sorted() {
        print("Family: \(family)")
        for name in UIFont.fontNames(forFamilyName: family) {
            print("   - \(name)")
        }
    }
}
```

Busca "Saira" en la salida de consola.

---

## Notas sobre la fuente Saira

Según el manual de marca de Calei:
- **Saira Bold** - Para títulos principales
- **Saira SemiBold** - Para subtítulos y encabezados
- **Saira Medium** - Para texto destacado y botones
- **Saira Regular** - Para texto del cuerpo

## Fallback

Si las fuentes no están disponibles, el sistema usará `.system` de iOS como fallback.
