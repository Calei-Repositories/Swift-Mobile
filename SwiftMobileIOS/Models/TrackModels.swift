import Foundation
import CoreLocation

// MARK: - Track (Recorrido)
struct Track: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let userId: Int?
    let completed: Bool?
    let createdAt: String?
    let updatedAt: String?
    let subTracks: [SubTrack]?
    let salePoints: [SalePoint]?
    
    /// Conteo de puntos de venta (puede venir del backend para optimizar listados)
    /// Nombres alternativos que el backend podría usar
    let salePointsCount: Int?
    let _count: CountFields?
    
    /// Estructura para el patrón _count de Prisma/ORMs
    struct CountFields: Codable, Hashable {
        let salePoints: Int?
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, userId, completed, createdAt, updatedAt
        case subTracks, salePoints, salePointsCount
        case _count
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var formattedDate: String {
        guard let createdAt = createdAt else { return "" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: createdAt) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_AR")
            return formatter.string(from: date)
        }
        return createdAt
    }
    
    var totalDistance: Double {
        guard let subTracks = subTracks else { return 0 }
        return subTracks.reduce(0) { $0 + ($1.distance ?? 0) }
    }
    
    /// Todas las coordenadas de todos los subtracks combinadas
    var allCoordinates: [CLLocationCoordinate2D] {
        guard let subTracks = subTracks else { return [] }
        return subTracks.flatMap { $0.allCoordinates }
    }
    
    /// Cantidad de puntos de venta
    /// Prioridad: salePointsCount > _count.salePoints > salePoints.count
    var pointsCount: Int {
        if let count = salePointsCount {
            return count
        }
        if let count = _count?.salePoints {
            return count
        }
        return salePoints?.count ?? 0
    }
    
    var isActive: Bool {
        !(completed ?? false)
    }
}

// MARK: - SubTrack (Segmento GPS)
/// Representa un segmento GPS grabado con array de coordenadas
struct SubTrack: Codable, Identifiable {
    let id: String
    let coordinates: [SubTrackCoordinate]?
    let points: [SubTrackPoint]?
    let startTime: String?
    let endTime: String?
    let distance: Double?
    let paused: Bool?
    
    /// Coordenada simple en el array
    struct SubTrackCoordinate: Codable {
        let lat: Double
        let lng: Double
    }
    
    /// Punto con timestamp opcional
    struct SubTrackPoint: Codable {
        let lat: Double
        let lng: Double
        let timestamp: String?
    }
    
    /// Devuelve todas las coordenadas como CLLocationCoordinate2D
    var allCoordinates: [CLLocationCoordinate2D] {
        if let coords = coordinates {
            return coords.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        }
        if let pts = points {
            return pts.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        }
        return []
    }
    
    /// Primera coordenada del segmento
    var firstCoordinate: CLLocationCoordinate2D? {
        allCoordinates.first
    }
    
    /// Última coordenada del segmento
    var lastCoordinate: CLLocationCoordinate2D? {
        allCoordinates.last
    }
}

// MARK: - SalePoint (Punto de Venta)
struct SalePoint: Codable, Identifiable {
    let id: Int
    let trackId: Int?
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let email: String?
    let contactName: String?
    let notes: String?
    let statusId: Int?
    let zoneId: Int?
    let createdAt: String?
    let status: SalePointStatus?
    let zone: Zone?
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Status
struct SalePointStatus: Codable, Identifiable {
    let id: Int
    let name: String
    let color: String?
}

// MARK: - Zone
struct Zone: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Request Models
struct CreateTrackRequest: Encodable {
    let name: String
    let description: String?
}

/// Punto GPS individual con timestamp
struct RoutePoint: Codable {
    let lat: Double
    let lng: Double
    let timestamp: String?
    
    init(lat: Double, lng: Double, timestamp: String? = nil) {
        self.lat = lat
        self.lng = lng
        self.timestamp = timestamp
    }
}

/// Request para crear un SubTrack (segmento GPS completo)
/// El backend espera un segmento con array de coordenadas, no puntos individuales
struct CreateSubTrackRequest: Codable {
    let id: String
    let coordinates: [Coordinate]?
    let points: [RoutePoint]?
    let startTime: String
    let endTime: String
    let distance: Double
    let paused: Bool
    
    /// Coordenada simple para el array de coordinates
    struct Coordinate: Codable {
        let lat: Double
        let lng: Double
    }
    
    /// Crear un SubTrack a partir de un array de ubicaciones grabadas
    init(
        id: String = UUID().uuidString,
        routePoints: [(latitude: Double, longitude: Double, timestamp: Date)],
        startTime: Date,
        endTime: Date,
        distance: Double,
        paused: Bool = false
    ) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = id
        self.coordinates = nil
        self.points = routePoints.map { point in
            RoutePoint(
                lat: point.latitude,
                lng: point.longitude,
                timestamp: formatter.string(from: point.timestamp)
            )
        }
        self.startTime = formatter.string(from: startTime)
        self.endTime = formatter.string(from: endTime)
        self.distance = distance
        self.paused = paused
    }
}

/// Request legacy para puntos individuales (para compatibilidad offline)
struct CreateSubTrackPointRequest: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speed: Double?
    let accuracy: Double?
    let timestamp: String
    let distance: Double?
}

struct CreateSalePointRequest: Encodable {
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let email: String?
    let contactName: String?
    let notes: String?
    let statusId: Int?
    let zoneId: Int?
}

// MARK: - Response Wrappers
struct TracksResponse: Codable {
    let tracks: [Track]?
    let data: [Track]?
    
    var items: [Track] {
        tracks ?? data ?? []
    }
}

// MARK: - Transfer Request
struct TransferSalePointRequest: Encodable {
    let newTrackId: Int
}

// MARK: - Update Status Request
struct UpdateSalePointStatusRequest: Encodable {
    let statusId: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case statusId = "status_id"
        case notes
    }
}

// MARK: - Offline Storage Models

/// Modelo para almacenar puntos de venta pendientes de sincronización
struct PendingSalePoint: Codable, Identifiable {
    let id: UUID
    let trackId: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    var syncStatus: SyncStatus
    
    enum SyncStatus: String, Codable {
        case pending
        case syncing
        case synced
        case failed
    }
    
    init(trackId: Int, name: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.trackId = trackId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.syncStatus = .pending
    }
    
    func toRequest() -> CreateSalePointRequest {
        CreateSalePointRequest(
            name: name,
            address: nil,
            latitude: latitude,
            longitude: longitude,
            phone: nil,
            email: nil,
            contactName: nil,
            notes: nil,
            statusId: nil,
            zoneId: nil
        )
    }
}

/// Modelo para almacenar subtracks pendientes de sincronización
struct PendingSubTrack: Codable, Identifiable {
    let id: UUID
    let trackId: Int
    let subTrack: CreateSubTrackRequest
    var syncStatus: PendingSalePoint.SyncStatus
    
    init(trackId: Int, subTrack: CreateSubTrackRequest) {
        self.id = UUID()
        self.trackId = trackId
        self.subTrack = subTrack
        self.syncStatus = .pending
    }
}

/// Estado de grabación persistente para restaurar después de cerrar la app
struct RecordingState: Codable {
    let trackId: Int
    let trackName: String
    let startTime: Date
    let totalDistance: Double
    let pointsCount: Int
    let isPaused: Bool
    let recordedCoordinates: [StoredCoordinate]
    
    struct StoredCoordinate: Codable {
        let latitude: Double
        let longitude: Double
        let timestamp: Date
    }
}

