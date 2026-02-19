import Foundation
import CoreLocation
import SwiftUI

// MARK: - GeoZone (Zona Geográfica)

/// Representa una zona geográfica con perímetro definido por puntos
struct GeoZone: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let color: String?
    let isDangerous: Bool?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?
    let boundaryPoints: [BoundaryPoint]?
    
    /// Puntos de venta incluidos en la zona (si el backend los incluye)
    let salePoints: [ZoneSalePoint]?
    
    /// Conteos opcionales del backend
    let _count: ZoneCountFields?
    
    struct ZoneCountFields: Codable, Hashable {
        let boundaryPoints: Int?
        let salePoints: Int?
        let assignments: Int?
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, color, boundaryPoints, salePoints
        case isDangerous, is_dangerous
        case isActive, is_active
        case createdAt, created_at
        case updatedAt, updated_at
        case _count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        boundaryPoints = try container.decodeIfPresent([BoundaryPoint].self, forKey: .boundaryPoints)
        salePoints = try container.decodeIfPresent([ZoneSalePoint].self, forKey: .salePoints)
        _count = try container.decodeIfPresent(ZoneCountFields.self, forKey: ._count)
        
        // isDangerous: probar ambos formatos
        if let dangerous = try? container.decodeIfPresent(Bool.self, forKey: .isDangerous) {
            isDangerous = dangerous
        } else {
            isDangerous = try container.decodeIfPresent(Bool.self, forKey: .is_dangerous)
        }
        
        // isActive: probar ambos formatos
        if let active = try? container.decodeIfPresent(Bool.self, forKey: .isActive) {
            isActive = active
        } else {
            isActive = try container.decodeIfPresent(Bool.self, forKey: .is_active)
        }
        
        // createdAt: probar ambos formatos
        if let created = try? container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = created
        } else {
            createdAt = try container.decodeIfPresent(String.self, forKey: .created_at)
        }
        
        // updatedAt: probar ambos formatos
        if let updated = try? container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = updated
        } else {
            updatedAt = try container.decodeIfPresent(String.self, forKey: .updated_at)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(isDangerous, forKey: .isDangerous)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(boundaryPoints, forKey: .boundaryPoints)
        try container.encodeIfPresent(salePoints, forKey: .salePoints)
        try container.encodeIfPresent(_count, forKey: ._count)
    }
    
    static func == (lhs: GeoZone, rhs: GeoZone) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Computed Properties
    
    /// Color hexadecimal para mostrar
    var displayColor: String {
        if isDangerous == true {
            return "#EF4444" // CaleiColors.error (rojo)
        }
        return "#4FD1C5" // CaleiColors.accent (turquesa)
    }
    
    /// Color SwiftUI para visualización
    /// Rojo si es zona peligrosa, turquesa (accent) si no lo es
    var swiftUIDisplayColor: Color {
        if isDangerous == true {
            return CaleiColors.error
        }
        return CaleiColors.accent
    }
    
    var boundaryPointsCount: Int {
        _count?.boundaryPoints ?? boundaryPoints?.count ?? 0
    }
    
    /// Conteo de puntos de venta: primero de _count, luego del array salePoints
    var salePointsCount: Int {
        _count?.salePoints ?? salePoints?.count ?? 0
    }
    
    var assignmentsCount: Int {
        _count?.assignments ?? 0
    }
    
    var formattedDate: String {
        guard let createdAt = createdAt else { return "" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: createdAt) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "es_AR")
            return formatter.string(from: date)
        }
        return createdAt
    }
    
    /// Coordenadas del perímetro para dibujar en mapa
    var polygonCoordinates: [CLLocationCoordinate2D] {
        guard let points = boundaryPoints else { return [] }
        return points
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            .compactMap { $0.coordinate }
    }
    
    /// Centro aproximado de la zona (centroide)
    var centerCoordinate: CLLocationCoordinate2D? {
        let coords = polygonCoordinates
        guard !coords.isEmpty else { return nil }
        
        let sumLat = coords.reduce(0) { $0 + $1.latitude }
        let sumLng = coords.reduce(0) { $0 + $1.longitude }
        
        return CLLocationCoordinate2D(
            latitude: sumLat / Double(coords.count),
            longitude: sumLng / Double(coords.count)
        )
    }
    
    // MARK: - Manual Init (for Previews/Testing)
    
    init(
        id: Int,
        name: String,
        description: String? = nil,
        color: String? = nil,
        isDangerous: Bool? = nil,
        isActive: Bool? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        boundaryPoints: [BoundaryPoint]? = nil,
        salePoints: [ZoneSalePoint]? = nil,
        _count: ZoneCountFields? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.isDangerous = isDangerous
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.boundaryPoints = boundaryPoints
        self.salePoints = salePoints
        self._count = _count
    }
}

// MARK: - BoundaryPoint (Punto de Perímetro)

/// Representa un punto del perímetro de una zona
struct BoundaryPoint: Codable, Identifiable, Equatable, Hashable {
    let id: Int?
    let zoneId: Int?
    let order: Int?
    let createdAt: String?
    
    // Backend puede enviar "latitude"/"longitude" o "lat"/"lng"
    private let latitude: Double?
    private let longitude: Double?
    private let lat: Double?
    private let lng: Double?
    
    var actualLatitude: Double? {
        latitude ?? lat
    }
    
    var actualLongitude: Double? {
        longitude ?? lng
    }
    
    static func == (lhs: BoundaryPoint, rhs: BoundaryPoint) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = actualLatitude, let lng = actualLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    // MARK: - Manual Init (for Previews/Testing)
    
    init(
        id: Int? = nil,
        zoneId: Int? = nil,
        latitude: Double,
        longitude: Double,
        order: Int? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.zoneId = zoneId
        self.latitude = latitude
        self.longitude = longitude
        self.lat = nil
        self.lng = nil
        self.order = order
        self.createdAt = createdAt
    }
}

// MARK: - ZoneSalePoint (Punto de venta básico incluido en zona)

/// Representa un punto de venta básico incluido en la respuesta de zonas
/// Contiene solo los campos esenciales (id, name, lat, lng)
struct ZoneSalePoint: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String?
    
    // Soporta "latitude"/"longitude" o "lat"/"lng"
    private let latitude: Double?
    private let longitude: Double?
    private let lat: Double?
    private let lng: Double?
    
    var actualLatitude: Double? {
        latitude ?? lat
    }
    
    var actualLongitude: Double? {
        longitude ?? lng
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = actualLatitude, let lng = actualLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    static func == (lhs: ZoneSalePoint, rhs: ZoneSalePoint) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ZoneAssignment (Asignación de Zona)

/// Representa la asignación de un usuario a una zona
struct ZoneAssignment: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let zoneId: Int?
    let userId: Int?
    let assignedAt: String?
    let assignedBy: Int?
    let isActive: Bool?
    let user: AssignedUser?
    let zone: AssignedZone?
    
    struct AssignedUser: Codable, Hashable {
        let id: Int
        let username: String?
        let name: String?
        let email: String?
        let role: UserRole?
    }
    
    struct AssignedZone: Codable, Hashable {
        let id: Int
        let name: String?
    }
    
    struct UserRole: Codable, Hashable {
        let number: Int?
        let name: String?
    }
    
    static func == (lhs: ZoneAssignment, rhs: ZoneAssignment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var formattedAssignedDate: String {
        guard let assignedAt = assignedAt else { return "" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: assignedAt) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_AR")
            return formatter.string(from: date)
        }
        return assignedAt
    }
}

// MARK: - Assignable User (Usuario para asignar)

/// Usuario con rol que puede ser asignado a una zona
struct AssignableUser: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let username: String
    let email: String?
    let createdAt: String?
    let role: UserRoleInfo?
    
    struct UserRoleInfo: Codable, Hashable {
        let number: Int?
        let name: String?
    }
    
    static func == (lhs: AssignableUser, rhs: AssignableUser) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var displayName: String {
        username
    }
    
    var roleDisplayName: String {
        role?.name ?? "Sin rol"
    }
    
    var isSeller: Bool {
        role?.number == 3
    }
    
    var isDeliverer: Bool {
        role?.number == 5
    }
}

// MARK: - Request DTOs

/// DTO para crear una zona
struct CreateZoneRequest: Codable {
    let name: String
    let isDangerous: Bool?
    let boundaryPoints: [BoundaryPointInput]?
    
    struct BoundaryPointInput: Codable {
        let latitude: Double
        let longitude: Double
        let order: Int
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case isDangerous = "is_dangerous"
        case boundaryPoints
    }
}

/// DTO para actualizar una zona
struct UpdateZoneRequest: Codable {
    let name: String?
    let isDangerous: Bool?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case isDangerous = "is_dangerous"
        case isActive = "is_active"
    }
}

/// DTO para agregar puntos al perímetro
struct AddBoundaryPointsRequest: Codable {
    let points: [BoundaryPointInput]
    
    struct BoundaryPointInput: Codable {
        let latitude: Double
        let longitude: Double
        let order: Int
    }
}

/// DTO para búsqueda geográfica
struct ZoneAreaSearchRequest: Codable {
    // Búsqueda por radio
    let latitude: Double?
    let longitude: Double?
    let radius: Double? // en metros
    
    // Búsqueda por bounding box
    let minLat: Double?
    let maxLat: Double?
    let minLng: Double?
    let maxLng: Double?
}

/// DTO para crear asignación de zona
struct CreateZoneAssignmentRequest: Codable {
    let userId: Int
}

/// DTO para crear asignación de zona (backend espera zone_id y user_id)
struct ZoneAssignmentRequest: Codable {
    let zoneId: Int
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case zoneId = "zone_id"
        case userId = "user_id"
    }
}

/// Respuesta al crear una asignación
struct ZoneAssignmentResponse: Codable {
    let id: Int
    let zoneId: Int?
    let userId: Int?
    let assignedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case zoneId = "zone_id"
        case userId = "user_id"
        case assignedAt = "assigned_at"
    }
}

/// Respuesta al eliminar una asignación
struct RemoveAssignmentResponse: Codable {
    let message: String?
    let removedAssignment: RemovedAssignmentInfo?
    
    struct RemovedAssignmentInfo: Codable {
        let id: Int?
        let userId: Int?
        let zoneId: Int?
        let user: String?
        let zone: String?
    }
}

// MARK: - Response DTOs

/// Respuesta de lista de zonas
struct ZonesListResponse: Codable {
    let zones: [GeoZone]?
    let data: [GeoZone]?
    let total: Int?
    let page: Int?
    let limit: Int?
    
    var items: [GeoZone] {
        zones ?? data ?? []
    }
}

/// Respuesta de zona individual
struct ZoneResponse: Codable {
    let zone: GeoZone?
    let data: GeoZone?
    
    var item: GeoZone? {
        zone ?? data
    }
}
