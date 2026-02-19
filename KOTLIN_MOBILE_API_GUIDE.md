# Orion Logistics Backend – Guía rápida de API (Android Kotlin/Java)

Esta guía apunta a una **primera versión** de una app Android que consume el backend (Railway) con **sesión por cookie**.

## 1) Base URL

- Base URL (Railway): `https://<tu-dominio-railway>`
- Todos los endpoints van bajo esa base.

Ejemplo:
- `https://orionlogistics-backend-staging.up.railway.app/auth/login`

## 2) Autenticación (sesión por cookie `sessionId`)

El backend usa una cookie HTTP-only llamada **`sessionId`**.

### 2.1 Login

- **POST** `/auth/login` (público)
- Body JSON:
  - `username` (string)
  - `password` (string)

Ejemplo request:

```http
POST /auth/login
Content-Type: application/json

{"username":"demo","password":"demo"}
```

Respuesta (ejemplo):

```json
{
  "id": 8,
  "username": "demo",
  "email": "demo@demo.com",
  "roles": [{"id": 5, "name": "entregador", "number": 5}]
}
```

**Importante**: el servidor responde con `Set-Cookie: sessionId=...; HttpOnly; ...`. La app **debe persistir y reenviar** esa cookie en todas las llamadas posteriores.

### 2.2 Obtener sesión actual (me)

- **GET** `/auth/me` (requiere cookie)

Uso típico:
- Al abrir la app: si existe cookie guardada, llamar `/auth/me`.
- Si responde 200 → sesión válida.
- Si responde 401 → pedir login.

### 2.3 Logout

- **POST** `/auth/logout` (requiere cookie)

La cookie se invalida en DB y el server intenta limpiar `sessionId`.

### 2.4 Cómo manejar cookies en Android

Recomendación: usar **OkHttp** con un `CookieJar` persistente.

Pseudocódigo (idea):

```kotlin
val cookieJar = object : CookieJar {
  private val store = mutableMapOf<String, List<Cookie>>()

  override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
    // Guardar cookies por host (y si querés, persistir a SharedPreferences)
    store[url.host] = cookies
  }

  override fun loadForRequest(url: HttpUrl): List<Cookie> {
    return store[url.host].orEmpty()
  }
}

val okHttp = OkHttpClient.Builder()
  .cookieJar(cookieJar)
  .build()
```

Notas:
- Para una app real: persistir `sessionId` en storage seguro.
- En Retrofit: usar el `OkHttpClient` anterior.

## 3) Endpoints principales para una app de Repartidor

Todos estos requieren sesión (cookie `sessionId`).

### 3.1 Mis repartos

- **GET** `/dealer/deliveries?status=all|pending|in_progress|completed`

### 3.2 Detalle de un reparto

- **GET** `/dealer/deliveries/:deliveryId`

### 3.3 Items (órdenes/reportes) del reparto

- **GET** `/dealer/deliveries/:deliveryId/items`

### 3.4 Detalle de un item (pedido/reporte)

- **GET** `/dealer/delivery-items/:itemId`

### 3.5 Actualizar un item (completar + líneas)

- **PATCH** `/dealer/delivery-items/:itemId`

Body:
- `status`: `pending` | `completed` | `postpone_rescue` | `postpone_next_week`
- `items`: array de líneas (opcional)
- `amount`: number (opcional)
- `note`: string (opcional)

Ejemplo (incluye descuento/garantía con cantidad negativa):

```json
{
  "status": "completed",
  "items": [
    {"productCode":"C1","quantity":1.0,"unitPrice":2700.0,"description":"Auriculares"},
    {"productCode":"C1","quantity":-1.0,"unitPrice":2700.0,"description":"Auriculares (Descuento)"}
  ]
}
```

Reglas:
- `quantity` puede ser negativa (descuento/garantía), pero **no puede ser 0**.
- `unitPrice` debe ser `>= 0`.

### 3.6 Buscar productos (para armar líneas)

- **GET** `/dealer/products?search=<texto>&limit=<n>`

### 3.7 Mapa del reparto (puntos incluidos + “ghosts”)

- **GET** `/dealer/deliveries/:deliveryId/map-overlay?n=<..>&s=<..>&e=<..>&w=<..>`

### 3.8 Marcar un punto nuevo (no se agrega al reparto)

- **POST** `/dealer/deliveries/:deliveryId/mark-new-sale-point`

Body:

```json
{ "name": "Punto Nuevo", "latitude": -31.34, "longitude": -64.27 }
```

Comportamiento:
- El backend intenta asignar `zoneId` **solo** si la coordenada cae dentro de una zona geográfica existente.
- Si no cae en ninguna zona, queda `zoneId = null` hasta que se cree una zona nueva (y se auto-asigne).

## 4) Endpoints útiles para Admin (si la app incluye modo admin)

### 4.0 Registrar usuarios y asignar roles (setup inicial)

#### Registrar usuario (público)

- **POST** `/users/register`

Body JSON:
- `username` (min 3)
- `email`
- `password` (min 8)

Ejemplo:

```json
{
  "username": "nuevo_user",
  "email": "nuevo_user@mail.com",
  "password": "SuperSecreta123"
}
```

Respuesta: devuelve el usuario creado (sin password).

#### Listar roles disponibles (público)

- **GET** `/roles`

Devuelve algo como:

```json
[
  { "number": 1, "name": "admin" },
  { "number": 5, "name": "entregador" },
  { "number": 6, "name": "seller" }
]
```

#### Asignar roles a un usuario (admin-only)

- **PUT** `/users/:userId/roles`

Body JSON:
- `roleIds`: array de números (son los `number` que devuelve `/roles`)

Ejemplo (hacer a un usuario entregador + seller):

```json
{ "roleIds": [5, 6] }
```

Notas:
- Esta llamada requiere estar logueado como admin (cookie `sessionId`).
- Para verificar, podés llamar `GET /auth/me` y ver el array `roles`.

### 4.1 Puntos marcados (mapa)

- **GET** `/admin/marked-sale-points/map`

Filtros:
- `zoneId=<id>` (zona geográfica real)
- `from=YYYY-MM-DD`, `to=YYYY-MM-DD`
- `markedBy=<userId>`
- bounds opcionales `n,s,e,w`

### 4.2 Zonas disponibles para filtrar puntos marcados

- **GET** `/admin/marked-sale-points/zones`

Devuelve una lista con conteo, incluyendo `zoneId = null` (sin zona).

### 4.3 Asignar zona a vendedor (endpoint existente)

- **POST** `/zone-assignments`

Body:

```json
{ "zone_id": 12, "user_id": 99 }
```

### 4.4 Listar usuarios por rol (para elegir vendedor)

- **GET** `/users/by-role?roleId=<n>` (admin-only)

Alternativa:
- **GET** `/users/sellers-and-deliverers` (admin-only)

## 5) Códigos de error esperables

- `401 Not authenticated`: falta cookie `sessionId`.
- `401 Invalid or expired session`: cookie presente pero sesión vencida/inválida.
- `400 Bad Request`: validación de DTO (por ejemplo `quantity == 0`).

## 6) Checklist de primera versión (repartidor)

- Login (`/auth/login`) y persistir cookie
- Validar sesión (`/auth/me`) al iniciar
- Listar repartos (`/dealer/deliveries`)
- Ver detalle (`/dealer/deliveries/:id`)
- Ver items (`/dealer/deliveries/:id/items`)
- Completar item (`PATCH /dealer/delivery-items/:itemId`) con líneas, incluyendo negativos
- Logout (`/auth/logout`)
