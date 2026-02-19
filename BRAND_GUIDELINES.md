# 📘 Manual de Marca Calei

**Versión:** 1.0  
**Última actualización:** Enero 2026  
**Uso:** Web, iOS (Swift), Android (Kotlin)

---

## 📑 Índice

1. [Identidad de Marca](#1-identidad-de-marca)
2. [Logo y Variantes](#2-logo-y-variantes)
3. [Paleta de Colores](#3-paleta-de-colores)
4. [Tipografía](#4-tipografía)
5. [Espaciado y Grid System](#5-espaciado-y-grid-system)
6. [Componentes UI](#6-componentes-ui)
7. [Iconografía](#7-iconografía)
8. [Ilustraciones y Fotografía](#8-ilustraciones-y-fotografía)
9. [Tono y Voz](#9-tono-y-voz)
10. [Implementación por Plataforma](#10-implementación-por-plataforma)

---

## 1. Identidad de Marca

### 1.1 Esencia de Calei

**Calei** es una plataforma de gestión integral para distribuidoras y negocios de consignación. La marca transmite:

| Atributo | Descripción |
|----------|-------------|
| **Profesionalismo** | Herramienta seria para negocios reales |
| **Tecnología** | Moderna, conectada, en tiempo real |
| **Confianza** | Datos seguros, métricas precisas |
| **Eficiencia** | Simplifica operaciones complejas |
| **Accesibilidad** | Fácil de usar para todos los roles |

### 1.2 Personalidad de Marca

- **Confiable** pero no aburrida
- **Técnica** pero accesible
- **Profesional** pero cercana
- **Innovadora** pero práctica

### 1.3 Propuesta de Valor

> "Control total de tu distribuidora en una sola plataforma: preventa, reparto, stock y métricas en tiempo real."

---

## 2. Logo y Variantes

### 2.1 Logo Principal (Logotipo)

<!-- INSERTAR IMAGEN: Logotipo.svg -->
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                   [LOGOTIPO CALEI]                      │
│                   Logotipo.svg                          │
│                                                         │
│                   Uso: Headers, documentos              │
│                   Fondo: Oscuro preferido               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Archivo:** `/Logotipo.svg`  
**Uso principal:** Navegación, headers, documentos oficiales  
**Fondo recomendado:** Oscuro (#1e2530)

### 2.2 Isotipo (Ícono)

<!-- INSERTAR IMAGEN: Isotipo.svg -->
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                    [ISOTIPO CALEI]                      │
│                     Isotipo.svg                         │
│                                                         │
│                   Uso: App icons, favicons              │
│                   Tamaño mínimo: 24x24px                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Archivo:** `/Isotipo.svg`  
**Uso:** App icons, favicons, espacios reducidos  
**Tamaño mínimo:** 24x24px

### 2.3 Logo Iluminado

<!-- INSERTAR IMAGEN: LogoCaleiImagen.jpg -->
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│               [LOGO CALEI ILUMINADO]                    │
│                LogoCaleiImagen.jpg                      │
│                                                         │
│                   Uso: Hero sections                    │
│                   Marketing, presentaciones             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Archivo:** `/LogoCaleiImagen.jpg`  
**Uso:** Hero sections, marketing, presentaciones

### 2.4 Área de Protección

El logo debe tener un área de respiro mínima equivalente a la altura de la "C" de Calei en todos sus lados.

```
          ┌───────────────────────────┐
          │     ↑                     │
          │     │ altura "C"          │
          │     ↓                     │
          │ ←──── CALEI ────→         │
          │     ↑                     │
          │     │ altura "C"          │
          │     ↓                     │
          └───────────────────────────┘
```

### 2.5 Usos Incorrectos ❌

- No estirar o distorsionar
- No rotar
- No cambiar colores del logo
- No agregar efectos (sombras, bordes)
- No colocar sobre fondos con poco contraste
- No usar versión pixelada

---

## 3. Paleta de Colores

### 3.1 Colores Primarios

#### Dark (Principal)
El color base de la marca. Usado en fondos, navegación y elementos principales.

| Formato | Valor |
|---------|-------|
| **Nombre** | Calei Dark |
| **HEX** | `#1e2530` |
| **RGB** | `30, 37, 48` |
| **HSL** | `217°, 23%, 15%` |
| **Swift (UIColor)** | `UIColor(red: 0.118, green: 0.145, blue: 0.188, alpha: 1.0)` |
| **SwiftUI** | `Color(red: 0.118, green: 0.145, blue: 0.188)` |
| **Kotlin (Compose)** | `Color(0xFF1E2530)` |
| **Kotlin (XML)** | `#FF1E2530` |
| **Tailwind** | `calei-dark` (custom) |

```
████████████████████████████████
████████████████████████████████  #1e2530
████████████████████████████████
```

#### Accent (Acento)
Color de acento para CTAs, highlights y elementos interactivos.

| Formato | Valor |
|---------|-------|
| **Nombre** | Calei Accent / Teal |
| **HEX** | `#4fd1c5` |
| **RGB** | `79, 209, 197` |
| **HSL** | `174°, 57%, 56%` |
| **Swift (UIColor)** | `UIColor(red: 0.310, green: 0.820, blue: 0.773, alpha: 1.0)` |
| **SwiftUI** | `Color(red: 0.310, green: 0.820, blue: 0.773)` |
| **Kotlin (Compose)** | `Color(0xFF4FD1C5)` |
| **Kotlin (XML)** | `#FF4FD1C5` |
| **Tailwind** | `calei-accent` (custom) |

```
████████████████████████████████
████████████████████████████████  #4fd1c5
████████████████████████████████
```

#### Accent Hover
Estado hover/pressed del color de acento.

| Formato | Valor |
|---------|-------|
| **Nombre** | Calei Accent Hover |
| **HEX** | `#38b2ac` |
| **RGB** | `56, 178, 172` |
| **Swift** | `UIColor(red: 0.220, green: 0.698, blue: 0.675, alpha: 1.0)` |
| **Kotlin** | `Color(0xFF38B2AC)` |

```
████████████████████████████████
████████████████████████████████  #38b2ac
████████████████████████████████
```

### 3.2 Colores Secundarios

#### Grises (Escala)

| Nombre | HEX | Uso |
|--------|-----|-----|
| Gray 50 | `#f8fafc` | Fondos claros |
| Gray 100 | `#f1f5f9` | Fondos alternos |
| Gray 200 | `#e2e8f0` | Bordes, divisores |
| Gray 300 | `#cbd5e1` | Iconos deshabilitados |
| Gray 400 | `#94a3b8` | Texto secundario |
| Gray 500 | `#64748b` | Texto terciario |
| Gray 600 | `#475569` | Texto body |
| Gray 700 | `#334155` | Texto énfasis |
| Gray 800 | `#1e293b` | Texto principal |
| Gray 900 | `#0f172a` | Títulos |

### 3.3 Colores Semánticos

| Estado | Color | HEX | Uso |
|--------|-------|-----|-----|
| **Success** | Verde | `#10b981` | Éxito, confirmaciones, entregas |
| **Warning** | Amarillo | `#f59e0b` | Alertas, pendientes |
| **Error** | Rojo | `#ef4444` | Errores, cancelaciones |
| **Info** | Azul | `#3b82f6` | Información, tips |

### 3.4 Gradientes

#### Gradient Principal (Hero)
```css
background: linear-gradient(135deg, #1e2530 0%, #0f172a 100%);
```

#### Gradient Accent
```css
background: linear-gradient(135deg, #4fd1c5 0%, #38b2ac 100%);
```

#### Gradient Text (para títulos destacados)
```css
background: linear-gradient(135deg, #4fd1c5 0%, #38b2ac 100%);
-webkit-background-clip: text;
-webkit-text-fill-color: transparent;
```

### 3.5 Transparencias

| Uso | Valor | Ejemplo |
|-----|-------|---------|
| Overlay oscuro | `rgba(30, 37, 48, 0.95)` | Modals, nav sticky |
| Overlay claro | `rgba(255, 255, 255, 0.95)` | Cards sobre imagen |
| Accent suave | `rgba(79, 209, 197, 0.1)` | Badges, highlights |
| Accent medio | `rgba(79, 209, 197, 0.2)` | Hover states |
| Blur background | `rgba(30, 37, 48, 0.8)` + `backdrop-blur` | Glass effect |

---

## 4. Tipografía

### 4.1 Familia Tipográfica

**Saira** - Google Fonts

```
Font Family: 'Saira', sans-serif
URL: https://fonts.google.com/specimen/Saira
```

#### Características
- Sans-serif geométrica moderna
- Excelente legibilidad en pantallas
- Amplia variedad de pesos
- Soporte multilenguaje

### 4.2 Pesos Utilizados

| Peso | Valor | Uso |
|------|-------|-----|
| Regular | 400 | Texto body, párrafos |
| Medium | 500 | Labels, navegación |
| SemiBold | 600 | Subtítulos, énfasis |
| Bold | 700 | Títulos, CTAs, headers |

### 4.3 Escala Tipográfica

#### Mobile (base: 16px)

| Elemento | Tamaño | Peso | Line Height |
|----------|--------|------|-------------|
| H1 | 28px / 1.75rem | 700 | 1.2 |
| H2 | 24px / 1.5rem | 700 | 1.25 |
| H3 | 20px / 1.25rem | 600 | 1.3 |
| H4 | 18px / 1.125rem | 600 | 1.35 |
| Body Large | 18px / 1.125rem | 400 | 1.6 |
| Body | 16px / 1rem | 400 | 1.6 |
| Body Small | 14px / 0.875rem | 400 | 1.5 |
| Caption | 12px / 0.75rem | 500 | 1.4 |
| Overline | 12px / 0.75rem | 600 | 1.2 |

#### Desktop (base: 16px)

| Elemento | Tamaño | Peso | Line Height |
|----------|--------|------|-------------|
| H1 | 48px / 3rem | 700 | 1.1 |
| H2 | 36px / 2.25rem | 700 | 1.2 |
| H3 | 28px / 1.75rem | 600 | 1.25 |
| H4 | 24px / 1.5rem | 600 | 1.3 |
| Body Large | 20px / 1.25rem | 400 | 1.6 |
| Body | 16px / 1rem | 400 | 1.6 |
| Body Small | 14px / 0.875rem | 400 | 1.5 |

### 4.4 Implementación

#### Web (CSS)
```css
@import url('https://fonts.googleapis.com/css2?family=Saira:wght@400;500;600;700&display=swap');

body {
  font-family: 'Saira', sans-serif;
}
```

#### iOS (Swift)
```swift
// Info.plist - agregar fuentes
// UIAppFonts: ["Saira-Regular.ttf", "Saira-Medium.ttf", "Saira-SemiBold.ttf", "Saira-Bold.ttf"]

extension UIFont {
    static func saira(_ weight: Weight, size: CGFloat) -> UIFont {
        let name: String
        switch weight {
        case .regular: name = "Saira-Regular"
        case .medium: name = "Saira-Medium"
        case .semibold: name = "Saira-SemiBold"
        case .bold: name = "Saira-Bold"
        default: name = "Saira-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}

// SwiftUI
extension Font {
    static func saira(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Saira", size: size).weight(weight)
    }
}
```

#### Android (Kotlin)
```kotlin
// res/font/saira.xml
<?xml version="1.0" encoding="utf-8"?>
<font-family xmlns:android="http://schemas.android.com/apk/res/android">
    <font android:fontStyle="normal" android:fontWeight="400" android:font="@font/saira_regular"/>
    <font android:fontStyle="normal" android:fontWeight="500" android:font="@font/saira_medium"/>
    <font android:fontStyle="normal" android:fontWeight="600" android:font="@font/saira_semibold"/>
    <font android:fontStyle="normal" android:fontWeight="700" android:font="@font/saira_bold"/>
</font-family>

// Compose
val SairaFamily = FontFamily(
    Font(R.font.saira_regular, FontWeight.Normal),
    Font(R.font.saira_medium, FontWeight.Medium),
    Font(R.font.saira_semibold, FontWeight.SemiBold),
    Font(R.font.saira_bold, FontWeight.Bold)
)

val Typography = Typography(
    headlineLarge = TextStyle(
        fontFamily = SairaFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        lineHeight = 40.sp
    ),
    // ... más estilos
)
```

---

## 5. Espaciado y Grid System

### 5.1 Escala de Espaciado

Basada en múltiplos de 4px (sistema de 4-point grid).

| Token | Valor | Uso |
|-------|-------|-----|
| `space-1` | 4px | Gaps mínimos |
| `space-2` | 8px | Padding interno pequeño |
| `space-3` | 12px | Gaps en listas |
| `space-4` | 16px | Padding estándar |
| `space-5` | 20px | - |
| `space-6` | 24px | Gaps entre secciones |
| `space-8` | 32px | Padding de cards |
| `space-10` | 40px | Separación mayor |
| `space-12` | 48px | Secciones |
| `space-16` | 64px | Secciones grandes |
| `space-20` | 80px | Hero padding |
| `space-24` | 96px | Mega espacios |

### 5.2 Grid System

#### Web (Container)
```css
.container {
  max-width: 1280px; /* 7xl */
  margin: 0 auto;
  padding: 0 16px; /* mobile */
}

@media (min-width: 640px) {
  .container { padding: 0 24px; }
}

@media (min-width: 1024px) {
  .container { padding: 0 32px; }
}
```

#### Mobile Apps

| Breakpoint | Columnas | Gutter | Margin |
|------------|----------|--------|--------|
| < 375px | 4 | 16px | 16px |
| 375-428px | 4 | 16px | 20px |
| > 428px (tablet) | 8 | 24px | 32px |

### 5.3 Border Radius

| Token | Valor | Uso |
|-------|-------|-----|
| `rounded-sm` | 4px | Inputs pequeños |
| `rounded` | 8px | Botones, inputs |
| `rounded-md` | 12px | Cards pequeñas |
| `rounded-lg` | 16px | Cards |
| `rounded-xl` | 20px | Modals |
| `rounded-2xl` | 24px | Cards grandes |
| `rounded-3xl` | 32px | Hero cards |
| `rounded-full` | 9999px | Badges, avatares |

---

## 6. Componentes UI

### 6.1 Botones

#### Primary Button
```
┌────────────────────────┐
│    Solicitar Demo      │  bg: #4fd1c5
│                        │  text: #1e2530
└────────────────────────┘  font-weight: 700
                            padding: 12px 24px
                            border-radius: 12px
```

**Estados:**
- Default: `bg-calei-accent`
- Hover: `bg-#38b2ac` + `transform: translateY(-2px)`
- Pressed: `bg-#2c9a94`
- Disabled: `opacity: 0.5`

#### Secondary Button
```
┌────────────────────────┐
│      Ver Módulos       │  bg: transparent
│                        │  border: 2px solid #4fd1c5
└────────────────────────┘  text: #4fd1c5
```

#### Ghost Button
```
┌────────────────────────┐
│      Cancelar          │  bg: transparent
│                        │  text: gray-600
└────────────────────────┘
```

### 6.2 Cards

#### Card Estándar
```css
.card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.card:hover {
  transform: translateY(-8px);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.15);
}
```

#### Card Destacada (Dark)
```css
.card-featured {
  background: #1e2530;
  border: 2px solid #4fd1c5;
  border-radius: 24px;
  padding: 32px;
}
```

### 6.3 Inputs

```css
.input {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 12px 16px;
  font-size: 16px;
  transition: all 0.2s;
}

.input:focus {
  border-color: #4fd1c5;
  box-shadow: 0 0 0 3px rgba(79, 209, 197, 0.2);
  outline: none;
}

.input::placeholder {
  color: #94a3b8;
}
```

### 6.4 Badges / Tags

```css
.badge {
  display: inline-block;
  padding: 6px 16px;
  background: rgba(79, 209, 197, 0.1);
  color: #4fd1c5;
  font-size: 14px;
  font-weight: 600;
  border-radius: 9999px;
}
```

### 6.5 Navigation

#### Desktop Nav
- Fondo: `#1e2530` con `backdrop-blur`
- Altura: 80px
- Links: `gray-300` → `white` on hover
- CTA: botón primary

#### Mobile Nav
- Hamburger icon: 24x24px
- Menu desplegable: full width
- Items: padding 12px vertical

### 6.6 Sombras

| Nivel | CSS | Uso |
|-------|-----|-----|
| sm | `0 1px 2px rgba(0,0,0,0.05)` | Elementos sutiles |
| default | `0 1px 3px rgba(0,0,0,0.1)` | Cards |
| md | `0 4px 6px rgba(0,0,0,0.1)` | Dropdowns |
| lg | `0 10px 15px rgba(0,0,0,0.1)` | Modals |
| xl | `0 20px 25px rgba(0,0,0,0.1)` | Floating |
| glow | `0 0 40px rgba(79,209,197,0.3)` | Accent elements |

---

## 7. Iconografía

### 7.1 Estilo de Iconos

- **Estilo:** Outline / Stroke
- **Stroke Width:** 2px
- **Tamaños:** 16px, 20px, 24px, 32px
- **Librería recomendada:** Heroicons (outline)

### 7.2 Iconos por Módulo

| Módulo | Icono | Descripción |
|--------|-------|-------------|
| Pre-venta | 🗺️ MapIcon | Mapas y rutas |
| Reparto | 🚚 TruckIcon | Entregas |
| Stock | 📦 CubeIcon | Inventario |
| Métricas | 📊 ChartBarIcon | Analytics |
| Usuarios | 👥 UsersIcon | Roles y permisos |
| WhatsApp | 💬 ChatBubbleIcon | Mensajería |
| QR | 📱 QrCodeIcon | Escaneo |
| GPS | 📍 MapPinIcon | Ubicación |
| Imprimir | 🖨️ PrinterIcon | Tickets |

### 7.3 Implementación

#### Web (Heroicons)
```html
<svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="..." />
</svg>
```

#### iOS (SF Symbols equivalentes)
```swift
Image(systemName: "map")
Image(systemName: "truck.box")
Image(systemName: "cube.box")
Image(systemName: "chart.bar")
```

#### Android (Material Icons)
```kotlin
Icon(Icons.Outlined.Map, contentDescription = "Mapa")
Icon(Icons.Outlined.LocalShipping, contentDescription = "Reparto")
```

---

## 8. Ilustraciones y Fotografía

### 8.1 Estilo de Ilustraciones

- **Estilo:** Flat design con gradientes sutiles
- **Colores:** Basados en paleta de marca
- **Complejidad:** Minimalista, formas geométricas

### 8.2 Fotografía

- **Temática:** Logística, distribución, tecnología móvil
- **Tratamiento:** Leve overlay oscuro para texto
- **Evitar:** Fotos genéricas de stock, baja calidad

### 8.3 Screenshots de la App

<!-- INSERTAR CAPTURAS AQUÍ -->

#### Captura 1: Mapa de Recorridos
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│              [SCREENSHOT: MAPA PRE-VENTA]               │
│                                                         │
│              Mostrar puntos en mapa                     │
│              con clusters y rutas                       │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Captura 2: Lista de Pedidos
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│            [SCREENSHOT: PANEL REPARTIDOR]               │
│                                                         │
│              Lista de entregas del día                  │
│              con estados y acciones                     │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Captura 3: Dashboard Admin
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│              [SCREENSHOT: DASHBOARD]                    │
│                                                         │
│              Métricas, gráficos                         │
│              y KPIs principales                         │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Captura 4: Ticket Bluetooth
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│            [SCREENSHOT: IMPRESIÓN TICKET]               │
│                                                         │
│              Preview del ticket                         │
│              antes de imprimir                          │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 9. Tono y Voz

### 9.1 Principios de Comunicación

| Principio | Descripción | Ejemplo ✓ | Ejemplo ✗ |
|-----------|-------------|-----------|-----------|
| **Claro** | Directo, sin rodeos | "Controlá tu stock en tiempo real" | "Optimiza la gestión integral de inventarios" |
| **Profesional** | Serio pero accesible | "Tu equipo en un solo lugar" | "¡Wow! Increíble app!" |
| **Confiable** | Transmite seguridad | "Datos seguros, siempre disponibles" | "Tal vez funcione" |
| **Orientado a acción** | Verbos activos | "Empezá hoy" | "Se podría empezar" |

### 9.2 Vocabulario de Marca

| Usar ✓ | Evitar ✗ |
|--------|----------|
| Distribuidora | Empresa |
| Punto de venta | Cliente |
| Repartidor | Chofer |
| Pre-ventista | Vendedor ambulante |
| Métricas | Estadísticas |
| En tiempo real | Actualizado |
| Control total | Visibilidad |

### 9.3 Mensajes de UI

#### Success
> ✓ "Pedido entregado correctamente"

#### Error
> ✗ "No pudimos procesar la entrega. Intentá de nuevo."

#### Empty State
> "Todavía no hay pedidos para hoy. ¡Buen momento para planificar!"

#### Loading
> "Cargando tus rutas..."

---

## 10. Implementación por Plataforma

### 10.1 Web (Tailwind CSS)

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        'calei-dark': '#1e2530',
        'calei-accent': '#4fd1c5',
        'calei-accentHover': '#38b2ac',
      },
      fontFamily: {
        sans: ['Saira', 'sans-serif'],
      },
      animation: {
        'fade-in': 'fadeIn 0.8s ease-out',
        'fade-in-up': 'fadeInUp 0.8s ease-out',
        'pulse-slow': 'pulse 4s infinite',
        'float': 'float 6s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(30px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-20px)' },
        },
      },
    },
  },
}
```

### 10.2 iOS (Swift / SwiftUI)

```swift
// CaleiTheme.swift
import SwiftUI

struct CaleiColors {
    static let dark = Color(hex: "#1e2530")
    static let accent = Color(hex: "#4fd1c5")
    static let accentHover = Color(hex: "#38b2ac")
    
    // Semantic
    static let success = Color(hex: "#10b981")
    static let warning = Color(hex: "#f59e0b")
    static let error = Color(hex: "#ef4444")
    static let info = Color(hex: "#3b82f6")
    
    // Grays
    static let gray50 = Color(hex: "#f8fafc")
    static let gray100 = Color(hex: "#f1f5f9")
    static let gray200 = Color(hex: "#e2e8f0")
    static let gray400 = Color(hex: "#94a3b8")
    static let gray600 = Color(hex: "#475569")
    static let gray900 = Color(hex: "#0f172a")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct CaleiTypography {
    static func heading1() -> Font { .custom("Saira-Bold", size: 32) }
    static func heading2() -> Font { .custom("Saira-Bold", size: 24) }
    static func heading3() -> Font { .custom("Saira-SemiBold", size: 20) }
    static func body() -> Font { .custom("Saira-Regular", size: 16) }
    static func caption() -> Font { .custom("Saira-Medium", size: 12) }
}

struct CaleiSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct CaleiCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// Ejemplo de botón
struct CaleiPrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(CaleiTypography.body().bold())
                .foregroundColor(CaleiColors.dark)
                .padding(.horizontal, CaleiSpacing.lg)
                .padding(.vertical, CaleiSpacing.md)
                .background(CaleiColors.accent)
                .cornerRadius(CaleiCornerRadius.md)
        }
    }
}
```

### 10.3 Android (Kotlin / Jetpack Compose)

```kotlin
// CaleiTheme.kt
package com.calei.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// Colors
object CaleiColors {
    val Dark = Color(0xFF1E2530)
    val Accent = Color(0xFF4FD1C5)
    val AccentHover = Color(0xFF38B2AC)
    
    // Semantic
    val Success = Color(0xFF10B981)
    val Warning = Color(0xFFF59E0B)
    val Error = Color(0xFFEF4444)
    val Info = Color(0xFF3B82F6)
    
    // Grays
    val Gray50 = Color(0xFFF8FAFC)
    val Gray100 = Color(0xFFF1F5F9)
    val Gray200 = Color(0xFFE2E8F0)
    val Gray400 = Color(0xFF94A3B8)
    val Gray600 = Color(0xFF475569)
    val Gray900 = Color(0xFF0F172A)
    
    // Transparencies
    val DarkOverlay = Color(0xF21E2530) // 95% opacity
    val AccentSoft = Color(0x1A4FD1C5) // 10% opacity
}

// Typography
val SairaFamily = FontFamily(
    Font(R.font.saira_regular, FontWeight.Normal),
    Font(R.font.saira_medium, FontWeight.Medium),
    Font(R.font.saira_semibold, FontWeight.SemiBold),
    Font(R.font.saira_bold, FontWeight.Bold)
)

object CaleiTypography {
    val Heading1 = TextStyle(
        fontFamily = SairaFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        lineHeight = 40.sp
    )
    val Heading2 = TextStyle(
        fontFamily = SairaFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp,
        lineHeight = 32.sp
    )
    val Heading3 = TextStyle(
        fontFamily = SairaFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        lineHeight = 28.sp
    )
    val Body = TextStyle(
        fontFamily = SairaFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp
    )
    val Caption = TextStyle(
        fontFamily = SairaFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp
    )
}

// Spacing
object CaleiSpacing {
    val XS = 4.dp
    val SM = 8.dp
    val MD = 16.dp
    val LG = 24.dp
    val XL = 32.dp
    val XXL = 48.dp
}

// Corner Radius
object CaleiCornerRadius {
    val SM = 8.dp
    val MD = 12.dp
    val LG = 16.dp
    val XL = 24.dp
}

// Ejemplo de botón
@Composable
fun CaleiPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        colors = ButtonDefaults.buttonColors(
            containerColor = CaleiColors.Accent,
            contentColor = CaleiColors.Dark
        ),
        shape = RoundedCornerShape(CaleiCornerRadius.MD)
    ) {
        Text(
            text = text,
            style = CaleiTypography.Body.copy(fontWeight = FontWeight.Bold)
        )
    }
}

// Ejemplo de Card
@Composable
fun CaleiCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(CaleiCornerRadius.LG),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, CaleiColors.Gray200),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        content()
    }
}
```

### 10.4 Recursos Android (XML)

```xml
<!-- res/values/colors.xml -->
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="calei_dark">#FF1E2530</color>
    <color name="calei_accent">#FF4FD1C5</color>
    <color name="calei_accent_hover">#FF38B2AC</color>
    
    <color name="calei_success">#FF10B981</color>
    <color name="calei_warning">#FFF59E0B</color>
    <color name="calei_error">#FFEF4444</color>
    <color name="calei_info">#FF3B82F6</color>
    
    <color name="gray_50">#FFF8FAFC</color>
    <color name="gray_100">#FFF1F5F9</color>
    <color name="gray_200">#FFE2E8F0</color>
    <color name="gray_400">#FF94A3B8</color>
    <color name="gray_600">#FF475569</color>
    <color name="gray_900">#FF0F172A</color>
</resources>

<!-- res/values/dimens.xml -->
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <dimen name="spacing_xs">4dp</dimen>
    <dimen name="spacing_sm">8dp</dimen>
    <dimen name="spacing_md">16dp</dimen>
    <dimen name="spacing_lg">24dp</dimen>
    <dimen name="spacing_xl">32dp</dimen>
    <dimen name="spacing_xxl">48dp</dimen>
    
    <dimen name="corner_sm">8dp</dimen>
    <dimen name="corner_md">12dp</dimen>
    <dimen name="corner_lg">16dp</dimen>
    <dimen name="corner_xl">24dp</dimen>
</resources>
```

---

## 📎 Anexos

### A. Checklist de Implementación

- [ ] Fuentes Saira instaladas
- [ ] Colores configurados
- [ ] Componentes base creados
- [ ] Iconografía definida
- [ ] Dark mode (si aplica)
- [ ] Animaciones implementadas
- [ ] Accesibilidad verificada

### B. Archivos de Assets

| Archivo | Formato | Uso |
|---------|---------|-----|
| Logotipo.svg | SVG | Web, print |
| Isotipo.svg | SVG | Icons, favicons |
| LogoCaleiImagen.jpg | JPG | Marketing |
| logo-orion.png | PNG | Cliente testimonial |
| Saira-*.ttf | TTF | iOS, Android |

### C. Links Útiles

- **Saira Font:** https://fonts.google.com/specimen/Saira
- **Heroicons:** https://heroicons.com/
- **Tailwind CSS:** https://tailwindcss.com/

---

**© 2026 Calei. Todos los derechos reservados.**

*Este manual es un documento vivo. Última actualización: Enero 2026.*
