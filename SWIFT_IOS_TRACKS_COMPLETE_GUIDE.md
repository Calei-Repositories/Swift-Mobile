# Guía de Integración iOS (Swift) - Módulo de Tracks y Puntos de Venta

## 📋 Índice

1. [Resumen de Arquitectura](#1-resumen-de-arquitectura)
2. [Autenticación](#2-autenticación)
3. [Endpoints de Tracks](#3-endpoints-de-tracks)
4. [Endpoints de Sale Points](#4-endpoints-de-sale-points)
5. [Endpoints de Statuses](#5-endpoints-de-statuses)
6. [Endpoints de Zones](#6-endpoints-de-zones)
7. [Modelos de Datos (Swift)](#7-modelos-de-datos-swift)
8. [Capa de Networking](#8-capa-de-networking)
9. [Repositorio](#9-repositorio)
10. [ViewModels](#10-viewmodels)
11. [Servicio de Ubicación](#11-servicio-de-ubicación)
12. [Vistas SwiftUI](#12-vistas-swiftui)
13. [Casos de Uso Completos](#13-casos-de-uso-completos)
14. [Configuración del Proyecto](#14-configuración-del-proyecto)

---

## 1. Resumen de Arquitectura

### Flujo de Trabajo del Preventista

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Crear Track │ ──▶ │ 2. Grabar GPS   │ ──▶ │ 3. Agregar      │
│    (Recorrido)  │     │   (SubTracks)   │     │   Sale Points   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                         │
                                                         ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │ 5. Ver Lista    │ ◀── │ 4. Completar    │
                        │   de Tracks     │     │    Track        │
                        └─────────────────┘     └─────────────────┘
```

### Relaciones de Entidades

```
Track (Recorrido)
├── subTracks[] (Segmentos GPS grabados)
│   └── coordinates[] (Puntos lat/lng)
└── salePoints[] (Puntos de venta visitados)
    └── currentStatus (Estado actual)
```

### Arquitectura MVVM

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    Views     │ ◀── │  ViewModels  │ ◀── │  Repository  │
│  (SwiftUI)   │     │ (@Published) │     │   (async)    │
└──────────────┘     └──────────────┘     └──────────────┘
                                                  │
                                          ┌──────────────┐
                                          │   Services   │
                                          │ (URLSession) │
                                          └──────────────┘
```

---

## 2. Autenticación

### Sistema de Sesión
El backend usa **cookies de sesión**. Después del login, el servidor envía una cookie `sessionId` que debe incluirse en todas las requests.

### Login
```
POST /auth/login
Content-Type: application/json

{
    "username": "string",
    "password": "string"
}
```

**Response (200):**
```json
{
    "id": 1,
    "username": "preventista1",
    "email": "preventista@email.com",
    "roles": ["preventista"]
}
```

**Cookie recibida:** `sessionId=uuid-session-id; HttpOnly; Secure; SameSite=None`

### Headers Requeridos
```
Content-Type: application/json
Accept: application/json
Cookie: sessionId=<valor-de-la-cookie>
```

---

## 3. Endpoints de Tracks

### 3.1 Listar Todos los Tracks

```
GET /tracks
```

**Response (200):**
```json
[
    {
        "id": 1,
        "name": "Recorrido Zona Norte",
        "description": "Visitas del lunes",
        "completed": false,
        "totalDistance": 5432.5,
        "totalDuration": 3600,
        "salePointsCount": 12,
        "createdAt": "2026-01-25T10:00:00.000Z",
        "updatedAt": "2026-01-25T12:30:00.000Z",
        "user": {
            "id": 1,
            "username": "preventista1"
        }
    }
]
```

**Notas:**
- `totalDistance`: metros totales recorridos
- `totalDuration`: segundos totales del recorrido
- `salePointsCount`: **REQUERIDO** - cantidad de puntos de venta marcados en el recorrido
- Solo devuelve tracks del usuario autenticado (o todos si es admin)

> ⚠️ **IMPORTANTE PARA BACKEND**: El campo `salePointsCount` es necesario para mostrar la cantidad de puntos en la lista de recorridos sin tener que cargar el detalle completo de cada track. Alternativa: usar el patrón `_count: { salePoints: number }` que usan ORMs como Prisma.

---

### 3.2 Crear Nuevo Track

```
POST /tracks
Content-Type: application/json

{
    "name": "Recorrido Zona Norte",
    "description": "Visitas programadas para el lunes",
    "subTracks": [],
    "totalDuration": null
}
```

**Request Body:**
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `name` | string | ✅ | Nombre del recorrido (no vacío) |
| `description` | string | ❌ | Descripción opcional |
| `subTracks` | SubTrack[] | ❌ | Array vacío al crear, se llena después |
| `totalDuration` | number | ❌ | Duración en segundos (se calcula automáticamente) |

**Response (201):**
```json
{
    "id": 5,
    "name": "Recorrido Zona Norte",
    "description": "Visitas programadas para el lunes",
    "completed": false,
    "totalDistance": 0,
    "totalDuration": null,
    "subTracks": [],
    "user_id": 1,
    "createdAt": "2026-01-25T14:00:00.000Z",
    "updatedAt": "2026-01-25T14:00:00.000Z"
}
```

---

### 3.3 Obtener Detalle de Track

```
GET /tracks/{id}
```

**Response (200):**
```json
{
    "id": 5,
    "name": "Recorrido Zona Norte",
    "description": "Visitas programadas para el lunes",
    "completed": false,
    "totalDistance": 2500.75,
    "totalDuration": 1800,
    "subTracks": [
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "coordinates": [
                {"lat": -33.4569, "lng": -70.6483},
                {"lat": -33.4571, "lng": -70.6485},
                {"lat": -33.4575, "lng": -70.6490}
            ],
            "startTime": "2026-01-25T14:00:00.000Z",
            "endTime": "2026-01-25T14:30:00.000Z",
            "distance": 2500.75,
            "paused": false
        }
    ],
    "user_id": 1,
    "createdAt": "2026-01-25T14:00:00.000Z",
    "updatedAt": "2026-01-25T14:30:00.000Z"
}
```

---

### 3.4 Agregar SubTrack (Segmento GPS) ⭐ IMPORTANTE

Este es el endpoint para guardar los puntos GPS grabados durante el recorrido.

```
POST /tracks/{id}/subtracks
Content-Type: application/json

{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "coordinates": [
        {"lat": -33.4569, "lng": -70.6483},
        {"lat": -33.4571, "lng": -70.6485},
        {"lat": -33.4575, "lng": -70.6490}
    ],
    "startTime": "2026-01-25T14:00:00.000Z",
    "endTime": "2026-01-25T14:30:00.000Z",
    "distance": 2500.75,
    "paused": false
}
```

**Request Body:**
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `id` | string | ✅ | UUID único del segmento |
| `coordinates` | Coordinate[] | ✅* | Array de puntos GPS |
| `points` | RoutePoint[] | ✅* | Alternativa a coordinates |
| `startTime` | string (ISO8601) | ✅ | Inicio del segmento |
| `endTime` | string (ISO8601) | ✅ | Fin del segmento |
| `distance` | number | ✅ | Distancia en metros |
| `paused` | boolean | ✅ | Si el segmento fue pausado |

*Nota: Enviar `coordinates` O `points`, no ambos. El backend acepta cualquiera de los dos formatos.

**Coordinate:**
```json
{"lat": -33.4569, "lng": -70.6483}
```

**RoutePoint (alternativa):**
```json
{"lat": -33.4569, "lng": -70.6483, "timestamp": "2026-01-25T14:00:00.000Z"}
```

**Response (200/201):**
```json
{
    "id": 5,
    "name": "Recorrido Zona Norte",
    "subTracks": [
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "coordinates": [...],
            "startTime": "2026-01-25T14:00:00.000Z",
            "endTime": "2026-01-25T14:30:00.000Z",
            "distance": 2500.75,
            "paused": false
        }
    ],
    "totalDistance": 2500.75,
    "totalDuration": 1800,
    ...
}
```

**⚠️ Comportamiento Importante:**
- El backend **recalcula automáticamente** `totalDistance` y `totalDuration`
- Los `subTracks` se **acumulan**, no se reemplazan
- Si el `id` no se provee, el backend genera uno automáticamente

---

### 3.5 Actualizar Estadísticas del Track

```
PATCH /tracks/{id}/stats
Content-Type: application/json

{
    "totalDistance": 5000.50,
    "totalDuration": 3600
}
```

**Request Body:**
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `totalDistance` | number | ❌ | Distancia total en metros |
| `totalDuration` | number | ❌ | Duración total en segundos |

**Response (200):** Track actualizado

---

### 3.6 Actualizar Track (General)

```
PATCH /tracks/{id}
Content-Type: application/json

{
    "name": "Nuevo nombre",
    "description": "Nueva descripción",
    "completed": true,
    "totalDuration": 7200
}
```

**Request Body (todos opcionales):**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `name` | string | Nuevo nombre |
| `description` | string | Nueva descripción |
| `completed` | boolean | Marcar como completado |
| `totalDuration` | number | Duración en segundos |
| `newSubTrack` | SubTrack | Agregar nuevo segmento (alternativa a POST /subtracks) |

**Response (200):** Track actualizado

---

### 3.7 Obtener SubTracks de un Track

```
GET /tracks/{id}/subtracks
```

**Response (200):**
```json
[
    {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "coordinates": [
            {"lat": -33.4569, "lng": -70.6483},
            {"lat": -33.4571, "lng": -70.6485}
        ],
        "startTime": "2026-01-25T14:00:00.000Z",
        "endTime": "2026-01-25T14:30:00.000Z",
        "distance": 2500.75,
        "paused": false
    }
]
```

---

### 3.8 Eliminar Track

```
DELETE /tracks/{id}
```

**Response (200):** Sin contenido

**Nota:** Es una eliminación lógica (soft delete). El track se marca como eliminado pero no se borra físicamente.

---

## 4. Endpoints de Sale Points

### 4.1 Listar Puntos de Venta de un Track

```
GET /tracks/{trackId}/sale-points
```

**Response (200):**
```json
[
    {
        "id": 1,
        "name": "Kiosko Don Juan",
        "latitude": -33.4569,
        "longitude": -70.6483,
        "trackId": 5,
        "zoneId": 2,
        "phone": "+54 11 1234-5678",
        "email": "donjuan@email.com",
        "description": "Kiosko en esquina",
        "ownerName": "Juan Pérez",
        "businessHours": {
            "from": "09:00",
            "to": "18:00",
            "days": "Lunes a Viernes"
        },
        "displayType": 3,
        "displaySupport": "wall_mounted",
        "installationNotes": "Instalar cerca de la caja",
        "whatsappSent": "si",
        "competencia": ["Coca-Cola", "Pepsi"],
        "competenciaDetalles": "Tienen heladera de Coca",
        "createdAt": "2026-01-25T14:30:00.000Z",
        "updatedAt": "2026-01-25T14:30:00.000Z",
        "currentStatus": {
            "id": 1,
            "statusChangeDate": "2026-01-25T14:30:00.000Z",
            "notes": "Visita inicial",
            "status": {
                "id": 2,
                "statusName": "Visitado"
            }
        },
        "zone": {
            "id": 2,
            "name": "Zona Norte"
        }
    }
]
```

---

### 4.2 Crear Punto de Venta ⭐ IMPORTANTE

```
POST /tracks/{trackId}/sale-points
Content-Type: application/json

{
    "name": "Kiosko Don Juan",
    "latitude": -33.4569,
    "longitude": -70.6483,
    "phone": "+54 11 1234-5678",
    "email": "donjuan@email.com",
    "description": "Kiosko en esquina, buena ubicación",
    "ownerName": "Juan Pérez",
    "businessHours": {
        "from": "09:00",
        "to": "18:00",
        "days": "Lunes a Viernes"
    },
    "displayType": 3,
    "displaySupport": "wall_mounted",
    "installationNotes": "Instalar cerca de la caja",
    "whatsappSent": "si",
    "competencia": ["Coca-Cola", "Pepsi"],
    "competenciaDetalles": "Tienen heladera de Coca",
    "statusId": 2,
    "statusNotes": "Primera visita realizada",
    "zoneId": null
}
```

**Request Body:**
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `name` | string | ✅ | Nombre del punto de venta |
| `latitude` | number | ✅ | Latitud (-90 a 90) |
| `longitude` | number | ✅ | Longitud (-180 a 180) |
| `phone` | string | ❌ | Teléfono de contacto |
| `email` | string | ❌ | Email (debe ser válido si se envía) |
| `description` | string | ❌ | Descripción/notas |
| `ownerName` | string | ❌ | Nombre del dueño/encargado |
| `businessHours` | object | ❌ | Horario de atención |
| `businessHours.from` | string | ❌ | Hora inicio (formato "HH:mm") |
| `businessHours.to` | string | ❌ | Hora fin (formato "HH:mm") |
| `businessHours.days` | string | ❌ | Días de atención |
| `displayType` | number | ❌ | Tipo de exhibidor (1-6) |
| `displaySupport` | string | ❌ | Tipo de soporte (ver opciones) |
| `installationNotes` | string | ❌ | Notas de instalación |
| `whatsappSent` | string | ❌ | "si", "no", o "nose" |
| `competencia` | string[] | ❌ | Array de competidores (máx 10) |
| `competenciaDetalles` | string | ❌ | Detalles de competencia (máx 1000 chars) |
| `statusId` | number | ❌ | ID del estado inicial (default: 16 = no_visitado) |
| `statusNotes` | string | ❌ | Notas del estado |
| `zoneId` | number/null | ❌ | ID de zona (auto-asignada si no se provee) |

**Valores de `displaySupport`:**
- `"wall_mounted"` - Montado en pared
- `"wooden_stand"` - Soporte de madera
- `"floor_stand"` - Soporte de piso
- `"counter_top"` - Sobre mostrador
- `"other"` - Otro

**Response (201):**
```json
{
    "id": 15,
    "name": "Kiosko Don Juan",
    "latitude": -33.4569,
    "longitude": -70.6483,
    "trackId": 5,
    "zoneId": 2,
    ...
}
```

**⚠️ Comportamiento Importante:**
- Si no se envía `zoneId`, el backend **auto-asigna** la zona basándose en las coordenadas
- Si no se envía `statusId`, se asigna automáticamente el estado "no_visitado" (ID 16)
- El punto se valida contra los límites de la zona asignada

---

### 4.3 Crear Punto de Venta desde Marcador (Simplificado)

```
POST /tracks/{trackId}/sale-points/markers
Content-Type: application/json

{
    "name": "Kiosko Don Juan",
    "status": "visitado",
    "description": "Kiosko en esquina",
    "position": [-33.4569, -70.6483],
    "zoneId": 2
}
```

**Request Body:**
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `name` | string | ✅ | Nombre |
| `status` | string | ✅ | Nombre del estado |
| `description` | string | ✅ | Descripción |
| `position` | [number, number] | ✅ | [latitud, longitud] |
| `zoneId` | number | ❌ | ID de zona |

---

### 4.4 Obtener Puntos de Venta como Marcadores

```
GET /tracks/{trackId}/sale-points/markers
```

**Response (200):** Array de puntos formateados para mostrar en mapa

---

### 4.5 Actualizar Estado de Punto de Venta

```
PATCH /tracks/{trackId}/sale-points/{salePointId}/status
Content-Type: application/json

{
    "status_id": 3,
    "notes": "Cliente interesado, volver la próxima semana"
}
```

**Request Body:**
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `status_id` | number | ✅ | ID del nuevo estado |
| `notes` | string | ❌ | Notas del cambio de estado |

**Response (200):** SalePoint actualizado

---

### 4.6 Eliminar Punto de Venta

```
DELETE /tracks/{trackId}/sale-points/{salePointId}
```

**Response (200):** Sin contenido

---

### 4.7 Transferir Punto de Venta a Otro Track

```
PATCH /tracks/{trackId}/sale-points/{salePointId}/transfer
Content-Type: application/json

{
    "newTrackId": 8
}
```

---

### 4.8 Reasignar Zona de un Punto de Venta

```
PATCH /tracks/{trackId}/sale-points/{salePointId}/zone
Content-Type: application/json

{
    "zoneId": 5
}
```

---

### 4.9 Buscar Puntos de Venta Cercanos

```
GET /sale-points/nearby?lat=-33.4569&lng=-70.6483&radius=1000
```

**Query Parameters:**
| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `lat` | number | ✅ | - | Latitud del centro |
| `lng` | number | ✅ | - | Longitud del centro |
| `radius` | number | ❌ | 1000 | Radio en metros |

**Response (200):** Array de SalePoints cercanos

---

### 4.10 Listar Todos los Puntos de Venta (Global)

```
GET /sale-points
```

**Response (200):** Array de todos los SalePoints del usuario

---

## 5. Endpoints de Statuses

### 5.1 Listar Todos los Estados (Público)

```
GET /statuses
```

**Response (200):**
```json
[
    {
        "id": 1,
        "statusName": "Pendiente",
        "statusType": "sale_point",
        "description": "Punto pendiente de visitar",
        "color": "#FFA500"
    },
    {
        "id": 2,
        "statusName": "Visitado",
        "statusType": "sale_point",
        "description": "Punto ya visitado",
        "color": "#00FF00"
    },
    {
        "id": 16,
        "statusName": "No Visitado",
        "statusType": "sale_point",
        "description": "Estado inicial por defecto",
        "color": "#808080"
    }
]
```

---

### 5.2 Listar Estados de Puntos de Venta (Público)

```
GET /statuses/sale-points
```

**Response (200):** Array filtrado solo con estados de tipo "sale_point"

---

## 6. Endpoints de Zones

### 6.1 Listar Todas las Zonas

```
GET /zones
```

**Response (200):**
```json
[
    {
        "id": 1,
        "name": "Zona Norte",
        "boundaryPoints": [
            {"lat": -33.4000, "lng": -70.6000},
            {"lat": -33.4000, "lng": -70.7000},
            {"lat": -33.5000, "lng": -70.7000},
            {"lat": -33.5000, "lng": -70.6000}
        ],
        "createdAt": "2026-01-01T00:00:00.000Z",
        "updatedAt": "2026-01-01T00:00:00.000Z"
    }
]
```

---

### 6.2 Obtener Zonas por Área

```
GET /zones/area?minLat=-33.5&maxLat=-33.4&minLng=-70.7&maxLng=-70.6
```

**Query Parameters:**
| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `minLat` | number | ✅ | Latitud mínima |
| `maxLat` | number | ✅ | Latitud máxima |
| `minLng` | number | ✅ | Longitud mínima |
| `maxLng` | number | ✅ | Longitud máxima |

---

## 7. Modelos de Datos (Swift)

### 7.1 Modelos Base

```swift
import Foundation

// MARK: - Coordinate

struct Coordinate: Codable, Equatable {
    let lat: Double
    let lng: Double
    
    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
    
    init(from location: CLLocationCoordinate2D) {
        self.lat = location.latitude
        self.lng = location.longitude
    }
    
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct RoutePoint: Codable {
    let lat: Double
    let lng: Double
    let timestamp: String?
}

// MARK: - SubTrack

struct SubTrack: Codable, Identifiable {
    let id: String
    let coordinates: [Coordinate]
    let startTime: String
    let endTime: String
    let distance: Double
    let paused: Bool
    
    var coordinateCount: Int { coordinates.count }
    
    var durationSeconds: Int? {
        let formatter = ISO8601DateFormatter()
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else { return nil }
        return Int(end.timeIntervalSince(start))
    }
}

struct AddSubTrackRequest: Codable {
    let id: String
    let coordinates: [Coordinate]?
    let points: [RoutePoint]?
    let startTime: String
    let endTime: String
    let distance: Double
    let paused: Bool
    
    init(
        id: String = UUID().uuidString,
        coordinates: [Coordinate],
        startTime: String,
        endTime: String,
        distance: Double,
        paused: Bool = false
    ) {
        self.id = id
        self.coordinates = coordinates
        self.points = nil
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.paused = paused
    }
    
    init(
        id: String = UUID().uuidString,
        points: [RoutePoint],
        startTime: String,
        endTime: String,
        distance: Double,
        paused: Bool = false
    ) {
        self.id = id
        self.coordinates = nil
        self.points = points
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.paused = paused
    }
}

// MARK: - Track

struct Track: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let completed: Bool
    let totalDistance: Double?
    let totalDuration: Int?
    let subTracks: [SubTrack]?
    let userId: Int?
    let user: TrackUser?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, completed
        case totalDistance, totalDuration, subTracks
        case userId = "user_id"
        case user, createdAt, updatedAt
    }
    
    var formattedDistance: String {
        guard let distance = totalDistance else { return "0 m" }
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }
    
    var formattedDuration: String {
        guard let duration = totalDuration else { return "0 min" }
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(minutes) min"
    }
    
    var subTrackCount: Int { subTracks?.count ?? 0 }
    var totalCoordinates: Int { subTracks?.reduce(0) { $0 + $1.coordinateCount } ?? 0 }
}

struct TrackUser: Codable {
    let id: Int
    let username: String
}

struct CreateTrackRequest: Codable {
    let name: String
    let description: String?
    let subTracks: [SubTrack]
    let totalDuration: Int?
    
    init(name: String, description: String? = nil) {
        self.name = name
        self.description = description
        self.subTracks = []
        self.totalDuration = nil
    }
}

struct UpdateTrackRequest: Codable {
    let name: String?
    let description: String?
    let completed: Bool?
    let totalDuration: Int?
    let newSubTrack: SubTrack?
    
    init(
        name: String? = nil,
        description: String? = nil,
        completed: Bool? = nil,
        totalDuration: Int? = nil,
        newSubTrack: SubTrack? = nil
    ) {
        self.name = name
        self.description = description
        self.completed = completed
        self.totalDuration = totalDuration
        self.newSubTrack = newSubTrack
    }
}

struct UpdateTrackStatsRequest: Codable {
    let totalDistance: Double?
    let totalDuration: Int?
}

// MARK: - Business Hours

struct BusinessHours: Codable {
    let from: String   // "09:00"
    let to: String     // "18:00"
    let days: String?  // "Lunes a Viernes"
    
    init(from: String, to: String, days: String? = nil) {
        self.from = from
        self.to = to
        self.days = days
    }
}

// MARK: - Sale Point

struct SalePoint: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let trackId: Int?
    let zoneId: Int?
    let phone: String?
    let email: String?
    let description: String?
    let ownerName: String?
    let businessHours: BusinessHours?
    let displayType: Int?
    let displaySupport: String?
    let installationNotes: String?
    let whatsappSent: String?
    let competencia: [String]?
    let competenciaDetalles: String?
    let createdAt: String?
    let updatedAt: String?
    let currentStatus: SalePointCurrentStatus?
    let zone: Zone?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var displaySupportType: DisplaySupport? {
        DisplaySupport(rawValue: displaySupport ?? "")
    }
    
    var whatsappSentStatus: WhatsappSentStatus? {
        WhatsappSentStatus(rawValue: whatsappSent ?? "")
    }
}

struct SalePointCurrentStatus: Codable {
    let id: Int
    let statusChangeDate: String
    let notes: String?
    let status: StatusInfo?
}

struct StatusInfo: Codable {
    let id: Int
    let statusName: String
}

struct CreateSalePointRequest: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let phone: String?
    let email: String?
    let description: String?
    let ownerName: String?
    let businessHours: BusinessHours?
    let displayType: Int?
    let displaySupport: String?
    let installationNotes: String?
    let whatsappSent: String?
    let competencia: [String]?
    let competenciaDetalles: String?
    let statusId: Int?
    let statusNotes: String?
    let zoneId: Int?
    
    init(
        name: String,
        latitude: Double,
        longitude: Double,
        phone: String? = nil,
        email: String? = nil,
        description: String? = nil,
        ownerName: String? = nil,
        businessHours: BusinessHours? = nil,
        displayType: Int? = nil,
        displaySupport: String? = nil,
        installationNotes: String? = nil,
        whatsappSent: String? = nil,
        competencia: [String]? = nil,
        competenciaDetalles: String? = nil,
        statusId: Int? = nil,
        statusNotes: String? = nil,
        zoneId: Int? = nil
    ) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.phone = phone
        self.email = email
        self.description = description
        self.ownerName = ownerName
        self.businessHours = businessHours
        self.displayType = displayType
        self.displaySupport = displaySupport
        self.installationNotes = installationNotes
        self.whatsappSent = whatsappSent
        self.competencia = competencia
        self.competenciaDetalles = competenciaDetalles
        self.statusId = statusId
        self.statusNotes = statusNotes
        self.zoneId = zoneId
    }
}

struct CreateFromMarkerRequest: Codable {
    let name: String
    let status: String
    let description: String
    let position: [Double]  // [lat, lng]
    let zoneId: Int?
    
    init(name: String, status: String, description: String, latitude: Double, longitude: Double, zoneId: Int? = nil) {
        self.name = name
        self.status = status
        self.description = description
        self.position = [latitude, longitude]
        self.zoneId = zoneId
    }
}

struct UpdateSalePointStatusRequest: Codable {
    let statusId: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case statusId = "status_id"
        case notes
    }
}

struct TransferSalePointRequest: Codable {
    let newTrackId: Int
}

struct ReassignZoneRequest: Codable {
    let zoneId: Int?
}

// MARK: - Status

struct Status: Codable, Identifiable {
    let id: Int
    let statusName: String
    let statusType: String
    let description: String?
    let color: String?  // Hex: "#FF0000"
    
    var uiColor: Color {
        guard let hex = color else { return .gray }
        return Color(hex: hex)
    }
}

// MARK: - Zone

struct Zone: Codable, Identifiable {
    let id: Int
    let name: String
    let boundaryPoints: [Coordinate]
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - API Error

struct APIErrorResponse: Codable {
    let statusCode: Int
    let message: MessageType
    let error: String?
    
    var firstMessage: String {
        message.firstMessage
    }
}

enum MessageType: Codable {
    case string(String)
    case array([String])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(
                MessageType.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
    
    var firstMessage: String {
        switch self {
        case .string(let s): return s
        case .array(let arr): return arr.first ?? "Error desconocido"
        }
    }
}
```

### 7.2 Enums de Soporte

```swift
import SwiftUI

// MARK: - Display Support

enum DisplaySupport: String, CaseIterable, Codable {
    case wallMounted = "wall_mounted"
    case woodenStand = "wooden_stand"
    case floorStand = "floor_stand"
    case counterTop = "counter_top"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .wallMounted: return "Pared"
        case .woodenStand: return "Madera"
        case .floorStand: return "Piso"
        case .counterTop: return "Mostrador"
        case .other: return "Otro"
        }
    }
}

// MARK: - WhatsApp Sent Status

enum WhatsappSentStatus: String, CaseIterable, Codable {
    case yes = "si"
    case no = "no"
    case unknown = "nose"
    
    var displayName: String {
        switch self {
        case .yes: return "Sí"
        case .no: return "No"
        case .unknown: return "No sé"
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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
```

---

## 8. Capa de Networking

### 8.1 Configuración de URLSession con Cookies

```swift
import Foundation

// MARK: - API Configuration

enum APIConfiguration {
    // Cambiar según el entorno
    #if DEBUG
    static let baseURL = "http://localhost:4000"
    // static let baseURL = "http://192.168.1.100:4000"  // Dispositivo real
    #else
    static let baseURL = "https://tu-proyecto.up.railway.app"
    #endif
    
    static let timeout: TimeInterval = 30
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String?)
    case unauthorized
    case forbidden
    case notFound
    case networkError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "Sin datos"
        case .decodingError(let error):
            return "Error de decodificación: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return message ?? "Error del servidor (\(code))"
        case .unauthorized:
            return "Sesión expirada. Iniciá sesión nuevamente."
        case .forbidden:
            return "No tenés permisos para esta acción"
        case .notFound:
            return "Recurso no encontrado"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .unknown:
            return "Error desconocido"
        }
    }
}

// MARK: - Network Service

actor NetworkService {
    
    static let shared = NetworkService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        // Configurar session con manejo de cookies
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.timeoutIntervalForRequest = APIConfiguration.timeout
        config.timeoutIntervalForResource = APIConfiguration.timeout
        
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Generic Request
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: APIConfiguration.baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        default:
            let errorMessage = try? decoder.decode(APIErrorResponse.self, from: data).firstMessage
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        }
    }
    
    func requestVoid(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws {
        guard let url = URL(string: APIConfiguration.baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        default:
            let errorMessage = try? decoder.decode(APIErrorResponse.self, from: data).firstMessage
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        }
    }
    
    func clearCookies() {
        HTTPCookieStorage.shared.cookies?.forEach {
            HTTPCookieStorage.shared.deleteCookie($0)
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
```

### 8.2 Auth Service

```swift
import Foundation

// MARK: - Auth Models

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let id: Int
    let username: String
    let email: String
    let roles: [String]?
}

// MARK: - Auth Service

actor AuthService {
    
    static let shared = AuthService()
    private let network = NetworkService.shared
    
    private init() {}
    
    func login(username: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(username: username, password: password)
        return try await network.request(
            endpoint: "/auth/login",
            method: .post,
            body: request
        )
    }
    
    func logout() async throws {
        try await network.requestVoid(endpoint: "/auth/logout", method: .post)
        await network.clearCookies()
    }
    
    func getCurrentUser() async throws -> LoginResponse {
        return try await network.request(endpoint: "/auth/me")
    }
}
```

### 8.3 Track Service

```swift
import Foundation

actor TrackService {
    
    static let shared = TrackService()
    private let network = NetworkService.shared
    
    private init() {}
    
    // MARK: - Tracks CRUD
    
    func getTracks() async throws -> [Track] {
        return try await network.request(endpoint: "/tracks")
    }
    
    func createTrack(name: String, description: String? = nil) async throws -> Track {
        let request = CreateTrackRequest(name: name, description: description)
        return try await network.request(
            endpoint: "/tracks",
            method: .post,
            body: request
        )
    }
    
    func getTrack(id: Int) async throws -> Track {
        return try await network.request(endpoint: "/tracks/\(id)")
    }
    
    func updateTrack(id: Int, update: UpdateTrackRequest) async throws -> Track {
        return try await network.request(
            endpoint: "/tracks/\(id)",
            method: .patch,
            body: update
        )
    }
    
    func deleteTrack(id: Int) async throws {
        try await network.requestVoid(endpoint: "/tracks/\(id)", method: .delete)
    }
    
    // MARK: - SubTracks
    
    func addSubTrack(trackId: Int, subTrack: AddSubTrackRequest) async throws -> Track {
        return try await network.request(
            endpoint: "/tracks/\(trackId)/subtracks",
            method: .post,
            body: subTrack
        )
    }
    
    func getSubTracks(trackId: Int) async throws -> [SubTrack] {
        return try await network.request(endpoint: "/tracks/\(trackId)/subtracks")
    }
    
    // MARK: - Stats
    
    func updateTrackStats(id: Int, totalDistance: Double?, totalDuration: Int?) async throws -> Track {
        let request = UpdateTrackStatsRequest(
            totalDistance: totalDistance,
            totalDuration: totalDuration
        )
        return try await network.request(
            endpoint: "/tracks/\(id)/stats",
            method: .patch,
            body: request
        )
    }
    
    // MARK: - Complete
    
    func completeTrack(id: Int) async throws -> Track {
        let update = UpdateTrackRequest(completed: true)
        return try await updateTrack(id: id, update: update)
    }
}
```

### 8.4 Sale Point Service

```swift
import Foundation

actor SalePointService {
    
    static let shared = SalePointService()
    private let network = NetworkService.shared
    
    private init() {}
    
    // MARK: - Track-scoped
    
    func getSalePointsByTrack(trackId: Int) async throws -> [SalePoint] {
        return try await network.request(endpoint: "/tracks/\(trackId)/sale-points")
    }
    
    func createSalePoint(trackId: Int, request: CreateSalePointRequest) async throws -> SalePoint {
        return try await network.request(
            endpoint: "/tracks/\(trackId)/sale-points",
            method: .post,
            body: request
        )
    }
    
    func createSalePointFromMarker(
        trackId: Int,
        name: String,
        status: String,
        description: String,
        latitude: Double,
        longitude: Double,
        zoneId: Int? = nil
    ) async throws -> SalePoint {
        let request = CreateFromMarkerRequest(
            name: name,
            status: status,
            description: description,
            latitude: latitude,
            longitude: longitude,
            zoneId: zoneId
        )
        return try await network.request(
            endpoint: "/tracks/\(trackId)/sale-points/markers",
            method: .post,
            body: request
        )
    }
    
    func deleteSalePoint(trackId: Int, salePointId: Int) async throws {
        try await network.requestVoid(
            endpoint: "/tracks/\(trackId)/sale-points/\(salePointId)",
            method: .delete
        )
    }
    
    func updateSalePointStatus(
        trackId: Int,
        salePointId: Int,
        statusId: Int,
        notes: String? = nil
    ) async throws -> SalePoint {
        let request = UpdateSalePointStatusRequest(statusId: statusId, notes: notes)
        return try await network.request(
            endpoint: "/tracks/\(trackId)/sale-points/\(salePointId)/status",
            method: .patch,
            body: request
        )
    }
    
    func transferSalePoint(trackId: Int, salePointId: Int, newTrackId: Int) async throws -> SalePoint {
        let request = TransferSalePointRequest(newTrackId: newTrackId)
        return try await network.request(
            endpoint: "/tracks/\(trackId)/sale-points/\(salePointId)/transfer",
            method: .patch,
            body: request
        )
    }
    
    func reassignZone(trackId: Int, salePointId: Int, zoneId: Int?) async throws -> SalePoint {
        let request = ReassignZoneRequest(zoneId: zoneId)
        return try await network.request(
            endpoint: "/tracks/\(trackId)/sale-points/\(salePointId)/zone",
            method: .patch,
            body: request
        )
    }
    
    // MARK: - Global
    
    func getAllSalePoints() async throws -> [SalePoint] {
        return try await network.request(endpoint: "/sale-points")
    }
    
    func getNearbySalePoints(latitude: Double, longitude: Double, radiusMeters: Int = 1000) async throws -> [SalePoint] {
        let queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(radiusMeters))
        ]
        return try await network.request(
            endpoint: "/sale-points/nearby",
            queryItems: queryItems
        )
    }
}
```

### 8.5 Status Service

```swift
import Foundation

actor StatusService {
    
    static let shared = StatusService()
    private let network = NetworkService.shared
    
    private init() {}
    
    func getAllStatuses() async throws -> [Status] {
        return try await network.request(endpoint: "/statuses")
    }
    
    func getSalePointStatuses() async throws -> [Status] {
        return try await network.request(endpoint: "/statuses/sale-points")
    }
}
```

### 8.6 Zone Service

```swift
import Foundation

actor ZoneService {
    
    static let shared = ZoneService()
    private let network = NetworkService.shared
    
    private init() {}
    
    func getAllZones() async throws -> [Zone] {
        return try await network.request(endpoint: "/zones")
    }
    
    func getZone(id: Int) async throws -> Zone {
        return try await network.request(endpoint: "/zones/\(id)")
    }
    
    func getZonesByArea(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double) async throws -> [Zone] {
        let queryItems = [
            URLQueryItem(name: "minLat", value: String(minLat)),
            URLQueryItem(name: "maxLat", value: String(maxLat)),
            URLQueryItem(name: "minLng", value: String(minLng)),
            URLQueryItem(name: "maxLng", value: String(maxLng))
        ]
        return try await network.request(endpoint: "/zones/area", queryItems: queryItems)
    }
}
```

---

## 9. Repositorio

```swift
import Foundation

// MARK: - Result Type

enum Result<T> {
    case success(T)
    case failure(NetworkError)
}

// MARK: - Track Repository

@MainActor
class TrackRepository: ObservableObject {
    
    static let shared = TrackRepository()
    
    private let trackService = TrackService.shared
    private let salePointService = SalePointService.shared
    private let statusService = StatusService.shared
    private let zoneService = ZoneService.shared
    
    private init() {}
    
    // MARK: - Tracks
    
    func getTracks() async -> Result<[Track]> {
        do {
            let tracks = try await trackService.getTracks()
            return .success(tracks)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func createTrack(name: String, description: String? = nil) async -> Result<Track> {
        do {
            let track = try await trackService.createTrack(name: name, description: description)
            return .success(track)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func getTrack(id: Int) async -> Result<Track> {
        do {
            let track = try await trackService.getTrack(id: id)
            return .success(track)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func addSubTrack(
        trackId: Int,
        coordinates: [Coordinate],
        startTime: Date,
        endTime: Date,
        distance: Double,
        paused: Bool = false
    ) async -> Result<Track> {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let request = AddSubTrackRequest(
            coordinates: coordinates,
            startTime: formatter.string(from: startTime),
            endTime: formatter.string(from: endTime),
            distance: distance,
            paused: paused
        )
        
        do {
            let track = try await trackService.addSubTrack(trackId: trackId, subTrack: request)
            return .success(track)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func completeTrack(id: Int) async -> Result<Track> {
        do {
            let track = try await trackService.completeTrack(id: id)
            return .success(track)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func updateTrackStats(id: Int, totalDistance: Double?, totalDuration: Int?) async -> Result<Track> {
        do {
            let track = try await trackService.updateTrackStats(
                id: id,
                totalDistance: totalDistance,
                totalDuration: totalDuration
            )
            return .success(track)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func deleteTrack(id: Int) async -> Result<Void> {
        do {
            try await trackService.deleteTrack(id: id)
            return .success(())
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    // MARK: - Sale Points
    
    func getSalePointsByTrack(trackId: Int) async -> Result<[SalePoint]> {
        do {
            let salePoints = try await salePointService.getSalePointsByTrack(trackId: trackId)
            return .success(salePoints)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func createSalePoint(trackId: Int, request: CreateSalePointRequest) async -> Result<SalePoint> {
        do {
            let salePoint = try await salePointService.createSalePoint(trackId: trackId, request: request)
            return .success(salePoint)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func updateSalePointStatus(
        trackId: Int,
        salePointId: Int,
        statusId: Int,
        notes: String? = nil
    ) async -> Result<SalePoint> {
        do {
            let salePoint = try await salePointService.updateSalePointStatus(
                trackId: trackId,
                salePointId: salePointId,
                statusId: statusId,
                notes: notes
            )
            return .success(salePoint)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func deleteSalePoint(trackId: Int, salePointId: Int) async -> Result<Void> {
        do {
            try await salePointService.deleteSalePoint(trackId: trackId, salePointId: salePointId)
            return .success(())
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    func getNearbySalePoints(latitude: Double, longitude: Double, radiusMeters: Int = 1000) async -> Result<[SalePoint]> {
        do {
            let salePoints = try await salePointService.getNearbySalePoints(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters
            )
            return .success(salePoints)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    // MARK: - Statuses
    
    func getSalePointStatuses() async -> Result<[Status]> {
        do {
            let statuses = try await statusService.getSalePointStatuses()
            return .success(statuses)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    // MARK: - Zones
    
    func getZones() async -> Result<[Zone]> {
        do {
            let zones = try await zoneService.getAllZones()
            return .success(zones)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
}
```

---

## 10. ViewModels

### 10.1 TracksListViewModel

```swift
import Foundation
import SwiftUI

@MainActor
class TracksListViewModel: ObservableObject {
    
    @Published var tracks: [Track] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository = TrackRepository.shared
    
    func loadTracks() async {
        isLoading = true
        errorMessage = nil
        
        switch await repository.getTracks() {
        case .success(let tracks):
            self.tracks = tracks
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createTrack(name: String, description: String?, onSuccess: @escaping (Track) -> Void) async {
        isLoading = true
        errorMessage = nil
        
        switch await repository.createTrack(name: name, description: description) {
        case .success(let track):
            await loadTracks()
            onSuccess(track)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteTrack(_ track: Track) async {
        switch await repository.deleteTrack(id: track.id) {
        case .success:
            tracks.removeAll { $0.id == track.id }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
```

### 10.2 TrackRecordingViewModel

```swift
import Foundation
import SwiftUI
import CoreLocation

@MainActor
class TrackRecordingViewModel: ObservableObject {
    
    let trackId: Int
    
    @Published var track: Track?
    @Published var salePoints: [SalePoint] = []
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordedCoordinates: [Coordinate] = []
    @Published var totalDistance: Double = 0
    @Published var recordingStartTime: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository = TrackRepository.shared
    private var lastLocation: CLLocation?
    
    init(trackId: Int) {
        self.trackId = trackId
    }
    
    func loadTrack() async {
        switch await repository.getTrack(id: trackId) {
        case .success(let track):
            self.track = track
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func loadSalePoints() async {
        switch await repository.getSalePointsByTrack(trackId: trackId) {
        case .success(let salePoints):
            self.salePoints = salePoints
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
    
    func startRecording() {
        recordedCoordinates = []
        totalDistance = 0
        lastLocation = nil
        recordingStartTime = Date()
        isRecording = true
        isPaused = false
    }
    
    func pauseRecording() {
        isPaused = true
    }
    
    func resumeRecording() {
        isPaused = false
    }
    
    func addCoordinate(location: CLLocation) {
        guard isRecording, !isPaused else { return }
        
        let coord = Coordinate(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        recordedCoordinates.append(coord)
        
        // Calcular distancia
        if let last = lastLocation {
            totalDistance += location.distance(from: last)
        }
        lastLocation = location
    }
    
    func stopRecording() async {
        guard isRecording, !recordedCoordinates.isEmpty, let startTime = recordingStartTime else {
            isRecording = false
            isPaused = false
            return
        }
        
        isLoading = true
        let endTime = Date()
        
        switch await repository.addSubTrack(
            trackId: trackId,
            coordinates: recordedCoordinates,
            startTime: startTime,
            endTime: endTime,
            distance: totalDistance,
            paused: false
        ) {
        case .success(let updatedTrack):
            self.track = updatedTrack
            self.recordedCoordinates = []
            self.totalDistance = 0
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
        
        isRecording = false
        isPaused = false
        isLoading = false
    }
    
    func completeTrack() async {
        isLoading = true
        
        switch await repository.completeTrack(id: trackId) {
        case .success(let updatedTrack):
            self.track = updatedTrack
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1f km", totalDistance / 1000)
        }
        return String(format: "%.0f m", totalDistance)
    }
    
    var formattedDuration: String {
        guard let start = recordingStartTime else { return "0:00" }
        let duration = Int(Date().timeIntervalSince(start))
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

### 10.3 AddSalePointViewModel

```swift
import Foundation
import SwiftUI
import CoreLocation

@MainActor
class AddSalePointViewModel: ObservableObject {
    
    let trackId: Int
    
    // Form fields
    @Published var name = ""
    @Published var phone = ""
    @Published var email = ""
    @Published var description = ""
    @Published var ownerName = ""
    @Published var businessHoursFrom = ""
    @Published var businessHoursTo = ""
    @Published var businessHoursDays = ""
    @Published var selectedDisplayType: Int?
    @Published var selectedDisplaySupport: DisplaySupport?
    @Published var installationNotes = ""
    @Published var selectedWhatsappSent: WhatsappSentStatus?
    @Published var competencia: [String] = []
    @Published var competenciaDetalles = ""
    @Published var selectedStatusId: Int?
    @Published var statusNotes = ""
    
    // Location
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var useCurrentLocation = true
    
    // State
    @Published var statuses: [Status] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var savedSalePoint: SalePoint?
    
    private let repository = TrackRepository.shared
    
    init(trackId: Int) {
        self.trackId = trackId
    }
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (useCurrentLocation || (latitude != 0 || longitude != 0))
    }
    
    func loadStatuses() async {
        isLoading = true
        
        switch await repository.getSalePointStatuses() {
        case .success(let statuses):
            self.statuses = statuses
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func setCurrentLocation(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
    
    func createSalePoint() async {
        guard isFormValid else { return }
        
        isSaving = true
        errorMessage = nil
        
        var businessHours: BusinessHours?
        if !businessHoursFrom.isEmpty && !businessHoursTo.isEmpty {
            businessHours = BusinessHours(
                from: businessHoursFrom,
                to: businessHoursTo,
                days: businessHoursDays.isEmpty ? nil : businessHoursDays
            )
        }
        
        let request = CreateSalePointRequest(
            name: name,
            latitude: latitude,
            longitude: longitude,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            description: description.isEmpty ? nil : description,
            ownerName: ownerName.isEmpty ? nil : ownerName,
            businessHours: businessHours,
            displayType: selectedDisplayType,
            displaySupport: selectedDisplaySupport?.rawValue,
            installationNotes: installationNotes.isEmpty ? nil : installationNotes,
            whatsappSent: selectedWhatsappSent?.rawValue,
            competencia: competencia.isEmpty ? nil : competencia,
            competenciaDetalles: competenciaDetalles.isEmpty ? nil : competenciaDetalles,
            statusId: selectedStatusId,
            statusNotes: statusNotes.isEmpty ? nil : statusNotes,
            zoneId: nil
        )
        
        switch await repository.createSalePoint(trackId: trackId, request: request) {
        case .success(let salePoint):
            self.savedSalePoint = salePoint
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    func addCompetencia(_ item: String) {
        guard competencia.count < 10, !item.isEmpty else { return }
        competencia.append(item)
    }
    
    func removeCompetencia(at index: Int) {
        guard index < competencia.count else { return }
        competencia.remove(at: index)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetSavedState() {
        savedSalePoint = nil
    }
}
```

---

## 11. Servicio de Ubicación

```swift
import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    // Callbacks
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // metros mínimos
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdating() {
        guard authorizationStatus == .authorizedAlways ||
              authorizationStatus == .authorizedWhenInUse else {
            locationError = "Permisos de ubicación no concedidos"
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestSingleLocation() {
        locationManager.requestLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }
}
```

---

## 12. Vistas SwiftUI

### 12.1 TracksListView

```swift
import SwiftUI

struct TracksListView: View {
    
    @StateObject private var viewModel = TracksListViewModel()
    @State private var showCreateSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.tracks.isEmpty {
                    ProgressView("Cargando recorridos...")
                } else if viewModel.tracks.isEmpty {
                    ContentUnavailableView(
                        "Sin recorridos",
                        systemImage: "map",
                        description: Text("Creá tu primer recorrido")
                    )
                } else {
                    List {
                        ForEach(viewModel.tracks) { track in
                            NavigationLink(destination: TrackDetailView(trackId: track.id)) {
                                TrackRowView(track: track)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteTrack(viewModel.tracks[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mis Recorridos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateTrackView { track in
                    showCreateSheet = false
                    // Navegar al nuevo track si es necesario
                }
            }
            .refreshable {
                await viewModel.loadTracks()
            }
            .task {
                await viewModel.loadTracks()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct TrackRowView: View {
    let track: Track
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(track.name)
                    .font(.headline)
                
                Spacer()
                
                if track.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if let description = track.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack(spacing: 16) {
                Label(track.formattedDistance, systemImage: "ruler")
                Label(track.formattedDuration, systemImage: "clock")
                Label("\(track.subTrackCount) seg.", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
```

### 12.2 CreateTrackView

```swift
import SwiftUI

struct CreateTrackView: View {
    
    @StateObject private var viewModel = TracksListViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    
    var onCreated: (Track) -> Void
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Información del Recorrido") {
                    TextField("Nombre *", text: $name)
                    
                    TextField("Descripción (opcional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button {
                        Task {
                            isCreating = true
                            await viewModel.createTrack(name: name, description: description.isEmpty ? nil : description) { track in
                                onCreated(track)
                                dismiss()
                            }
                            isCreating = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isCreating {
                                ProgressView()
                            } else {
                                Text("Crear Recorrido")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .navigationTitle("Nuevo Recorrido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
```

### 12.3 TrackDetailView

```swift
import SwiftUI
import MapKit

struct TrackDetailView: View {
    
    let trackId: Int
    
    @StateObject private var viewModel: TrackRecordingViewModel
    @StateObject private var locationService = LocationService.shared
    @State private var showAddSalePoint = false
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    init(trackId: Int) {
        self.trackId = trackId
        _viewModel = StateObject(wrappedValue: TrackRecordingViewModel(trackId: trackId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mapa
            Map(position: $mapCameraPosition) {
                // Ubicación actual
                if let location = locationService.currentLocation {
                    Marker("Mi ubicación", coordinate: location.coordinate)
                        .tint(.blue)
                }
                
                // Puntos de venta
                ForEach(viewModel.salePoints) { point in
                    Marker(point.name, coordinate: point.coordinate)
                        .tint(.green)
                }
                
                // Ruta grabada actualmente
                if !viewModel.recordedCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.recordedCoordinates.map { $0.clLocationCoordinate })
                        .stroke(.blue, lineWidth: 4)
                }
                
                // SubTracks guardados
                if let subTracks = viewModel.track?.subTracks {
                    ForEach(subTracks) { subTrack in
                        MapPolyline(coordinates: subTrack.coordinates.map { $0.clLocationCoordinate })
                            .stroke(.purple, lineWidth: 3)
                    }
                }
            }
            .frame(height: 300)
            
            // Panel de control
            VStack(spacing: 16) {
                // Stats
                HStack(spacing: 32) {
                    StatView(value: viewModel.formattedDistance, label: "Distancia")
                    StatView(value: "\(viewModel.recordedCoordinates.count)", label: "Puntos GPS")
                    StatView(value: "\(viewModel.salePoints.count)", label: "Clientes")
                }
                .padding()
                
                // Controles de grabación
                RecordingControlsView(
                    isRecording: viewModel.isRecording,
                    isPaused: viewModel.isPaused,
                    onStart: { viewModel.startRecording() },
                    onPause: { viewModel.pauseRecording() },
                    onResume: { viewModel.resumeRecording() },
                    onStop: { Task { await viewModel.stopRecording() } }
                )
                .padding(.horizontal)
                
                // Botón agregar punto de venta
                Button {
                    showAddSalePoint = true
                } label: {
                    Label("Agregar Punto de Venta", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                
                // Lista de puntos de venta
                if !viewModel.salePoints.isEmpty {
                    List(viewModel.salePoints) { point in
                        SalePointRowView(salePoint: point)
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
        }
        .navigationTitle(viewModel.track?.name ?? "Cargando...")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.track?.completed != true {
                    Button("Completar") {
                        Task { await viewModel.completeTrack() }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSalePoint) {
            AddSalePointView(trackId: trackId) { _ in
                showAddSalePoint = false
                Task { await viewModel.loadSalePoints() }
            }
        }
        .task {
            await viewModel.loadTrack()
            await viewModel.loadSalePoints()
        }
        .onAppear {
            locationService.requestPermission()
            locationService.startUpdating()
            locationService.onLocationUpdate = { location in
                viewModel.addCoordinate(location: location)
            }
        }
        .onDisappear {
            locationService.stopUpdating()
            locationService.onLocationUpdate = nil
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct RecordingControlsView: View {
    let isRecording: Bool
    let isPaused: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if !isRecording {
                Button(action: onStart) {
                    Label("Iniciar", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                if isPaused {
                    Button(action: onResume) {
                        Label("Continuar", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else {
                    Button(action: onPause) {
                        Label("Pausar", systemImage: "pause.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                
                Button(action: onStop) {
                    Label("Detener", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
    }
}

struct SalePointRowView: View {
    let salePoint: SalePoint
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(salePoint.name)
                    .font(.headline)
                if let desc = salePoint.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let status = salePoint.currentStatus?.status {
                Text(status.statusName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
}
```

---

## 13. Casos de Uso Completos

### 13.1 Flujo: Crear Track con SubTrack

```swift
class CreateTrackWithRecordingUseCase {
    
    private let repository = TrackRepository.shared
    
    func execute(
        name: String,
        description: String?,
        coordinates: [Coordinate],
        startTime: Date,
        endTime: Date,
        distance: Double
    ) async -> Result<Track> {
        // 1. Crear track
        switch await repository.createTrack(name: name, description: description) {
        case .success(let track):
            // 2. Si hay coordenadas, agregar subtrack
            if !coordinates.isEmpty {
                return await repository.addSubTrack(
                    trackId: track.id,
                    coordinates: coordinates,
                    startTime: startTime,
                    endTime: endTime,
                    distance: distance
                )
            }
            return .success(track)
            
        case .failure(let error):
            return .failure(error)
        }
    }
}
```

### 13.2 Flujo: Agregar Múltiples Puntos de Venta

```swift
class BatchCreateSalePointsUseCase {
    
    private let repository = TrackRepository.shared
    
    func execute(trackId: Int, requests: [CreateSalePointRequest]) async -> [Result<SalePoint>] {
        var results: [Result<SalePoint>] = []
        
        for request in requests {
            let result = await repository.createSalePoint(trackId: trackId, request: request)
            results.append(result)
        }
        
        return results
    }
}
```

---

## 14. Configuración del Proyecto

### 14.1 Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Permisos de ubicación -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Necesitamos tu ubicación para grabar el recorrido</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Necesitamos tu ubicación en segundo plano para grabar el recorrido completo mientras visitás clientes</string>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>
    
    <!-- Permitir HTTP en desarrollo -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
```

### 14.2 Estructura de Archivos Recomendada

```
YourApp/
├── App/
│   └── YourApp.swift
├── Models/
│   ├── Track.swift
│   ├── SalePoint.swift
│   ├── Status.swift
│   ├── Zone.swift
│   └── Enums.swift
├── Network/
│   ├── NetworkService.swift
│   ├── AuthService.swift
│   ├── TrackService.swift
│   ├── SalePointService.swift
│   ├── StatusService.swift
│   └── ZoneService.swift
├── Repository/
│   └── TrackRepository.swift
├── ViewModels/
│   ├── TracksListViewModel.swift
│   ├── TrackRecordingViewModel.swift
│   └── AddSalePointViewModel.swift
├── Services/
│   └── LocationService.swift
├── Views/
│   ├── Tracks/
│   │   ├── TracksListView.swift
│   │   ├── TrackDetailView.swift
│   │   └── CreateTrackView.swift
│   ├── SalePoints/
│   │   ├── AddSalePointView.swift
│   │   └── SalePointDetailView.swift
│   └── Components/
│       ├── StatView.swift
│       ├── RecordingControlsView.swift
│       └── SalePointRowView.swift
└── Resources/
    └── Info.plist
```

---

## 📋 Resumen de Endpoints

| Módulo | Método | Endpoint | Descripción |
|--------|--------|----------|-------------|
| **Auth** | POST | `/auth/login` | Iniciar sesión |
| **Auth** | POST | `/auth/logout` | Cerrar sesión |
| **Auth** | GET | `/auth/me` | Usuario actual |
| **Tracks** | GET | `/tracks` | Listar tracks |
| **Tracks** | POST | `/tracks` | Crear track |
| **Tracks** | GET | `/tracks/{id}` | Detalle track |
| **Tracks** | PATCH | `/tracks/{id}` | Actualizar track |
| **Tracks** | DELETE | `/tracks/{id}` | Eliminar track |
| **Tracks** | POST | `/tracks/{id}/subtracks` | Agregar GPS |
| **Tracks** | PATCH | `/tracks/{id}/stats` | Actualizar stats |
| **SalePoints** | GET | `/tracks/{id}/sale-points` | Listar puntos |
| **SalePoints** | POST | `/tracks/{id}/sale-points` | Crear punto |
| **SalePoints** | PATCH | `/tracks/{id}/sale-points/{id}/status` | Cambiar estado |
| **SalePoints** | DELETE | `/tracks/{id}/sale-points/{id}` | Eliminar punto |
| **SalePoints** | GET | `/sale-points/nearby` | Puntos cercanos |
| **Statuses** | GET | `/statuses/sale-points` | Estados disponibles |
| **Zones** | GET | `/zones` | Listar zonas |

---

## 📦 Dependencias (Swift Package Manager)

No se requieren dependencias externas. El proyecto usa:
- `Foundation` - Networking con URLSession
- `SwiftUI` - UI
- `CoreLocation` - GPS
- `MapKit` - Mapas
