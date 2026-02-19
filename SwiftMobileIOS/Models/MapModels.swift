import Foundation

struct MapOverlay: Codable {
    let points: [MapPoint]
    let ghosts: [MapPoint]?
}

struct MapPoint: Codable, Identifiable {
    let id: Int?
    let name: String?
    let latitude: Double
    let longitude: Double
}

struct MarkNewSalePointRequest: Encodable {
    let name: String
    let latitude: Double
    let longitude: Double
}

// Estructura auxiliar para decodificar el objeto zone anidado
private struct NestedZone: Decodable {
    let id: Int?
    let name: String?
}

// Estructura auxiliar para decodificar markedBy anidado
private struct NestedMarkedBy: Decodable {
    let userId: Int?
    let markedAt: String?
}

struct MarkedSalePoint: Decodable, Identifiable, Encodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let zoneId: Int?
    let zoneName: String?  // Nuevo: nombre de la zona
    
    // Campos opcionales que puede enviar el backend
    let address: String?
    let createdAt: String?
    let markedById: Int?
    
    // Campos extendidos para gestión de puntos de venta - Básico
    let description: String?
    let hasWhatsApp: Bool?
    let notes: String?           // Notas sobre el estado
    let competition: String?     // Competencia
    let status: String?          // no_visitado, visitado, pendiente, etc.
    
    // Campos de Contacto
    let managerName: String?     // Nombre del dueño/encargado
    let phone: String?           // Teléfono del local
    let email: String?           // Email del negocio
    let openingHours: String?    // Horario completo (legacy)
    let openingTimeFrom: String? // Hora desde (ej: "09:00")
    let openingTimeTo: String?   // Hora hasta (ej: "18:00")
    let workingDays: String?     // Días de atención (ej: "Lunes a Viernes")
    
    // Campos de Exhibidor
    let exhibitorType: String?   // Tipo de exhibidor
    let supportType: String?     // Tipo de soporte
    let installationNotes: String? // Notas de instalación
    
    // CodingKeys separados para decode y encode
    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, zoneId, zoneName
        case address, createdAt, markedById
        case description, hasWhatsApp, notes, competition, status
        case managerName, phone, email
        case openingHours, openingTimeFrom, openingTimeTo, workingDays
        case exhibitorType, supportType, installationNotes
        // Keys solo para decodificación de objetos anidados
        case zone, markedBy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Soportar lat/lng o latitude/longitude
        if let lat = try? container.decode(Double.self, forKey: .latitude) {
            latitude = lat
        } else {
            latitude = try container.decode(Double.self, forKey: .latitude)
        }
        
        if let lng = try? container.decode(Double.self, forKey: .longitude) {
            longitude = lng
        } else {
            longitude = try container.decode(Double.self, forKey: .longitude)
        }
        
        // Manejar zoneId que puede venir como Int o como objeto {id, name}
        if let directZoneId = try? container.decodeIfPresent(Int.self, forKey: .zoneId) {
            zoneId = directZoneId
            zoneName = try container.decodeIfPresent(String.self, forKey: .zoneName)
        } else if let nestedZone = try? container.decodeIfPresent(NestedZone.self, forKey: .zone) {
            zoneId = nestedZone.id
            zoneName = nestedZone.name
        } else {
            zoneId = nil
            zoneName = nil
        }
        
        address = try container.decodeIfPresent(String.self, forKey: .address)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        
        // Manejar markedById que puede venir como Int o como objeto {userId, ...}
        if let directMarkedById = try? container.decodeIfPresent(Int.self, forKey: .markedById) {
            markedById = directMarkedById
        } else if let nestedMarkedBy = try? container.decodeIfPresent(NestedMarkedBy.self, forKey: .markedBy) {
            markedById = nestedMarkedBy.userId
        } else {
            markedById = nil
        }
        
        // Campos básicos
        description = try container.decodeIfPresent(String.self, forKey: .description)
        hasWhatsApp = try container.decodeIfPresent(Bool.self, forKey: .hasWhatsApp)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        competition = try container.decodeIfPresent(String.self, forKey: .competition)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        
        // Campos de contacto
        managerName = try container.decodeIfPresent(String.self, forKey: .managerName)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        openingHours = try container.decodeIfPresent(String.self, forKey: .openingHours)
        openingTimeFrom = try container.decodeIfPresent(String.self, forKey: .openingTimeFrom)
        openingTimeTo = try container.decodeIfPresent(String.self, forKey: .openingTimeTo)
        workingDays = try container.decodeIfPresent(String.self, forKey: .workingDays)
        
        // Campos de exhibidor
        exhibitorType = try container.decodeIfPresent(String.self, forKey: .exhibitorType)
        supportType = try container.decodeIfPresent(String.self, forKey: .supportType)
        installationNotes = try container.decodeIfPresent(String.self, forKey: .installationNotes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encodeIfPresent(zoneId, forKey: .zoneId)
        try container.encodeIfPresent(zoneName, forKey: .zoneName)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(markedById, forKey: .markedById)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(hasWhatsApp, forKey: .hasWhatsApp)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(competition, forKey: .competition)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(managerName, forKey: .managerName)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(openingHours, forKey: .openingHours)
        try container.encodeIfPresent(openingTimeFrom, forKey: .openingTimeFrom)
        try container.encodeIfPresent(openingTimeTo, forKey: .openingTimeTo)
        try container.encodeIfPresent(workingDays, forKey: .workingDays)
        try container.encodeIfPresent(exhibitorType, forKey: .exhibitorType)
        try container.encodeIfPresent(supportType, forKey: .supportType)
        try container.encodeIfPresent(installationNotes, forKey: .installationNotes)
    }
    
    init(
        id: Int,
        name: String,
        latitude: Double,
        longitude: Double,
        zoneId: Int? = nil,
        zoneName: String? = nil,
        address: String? = nil,
        createdAt: String? = nil,
        markedById: Int? = nil,
        description: String? = nil,
        hasWhatsApp: Bool? = nil,
        notes: String? = nil,
        competition: String? = nil,
        status: String? = nil,
        managerName: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        openingHours: String? = nil,
        openingTimeFrom: String? = nil,
        openingTimeTo: String? = nil,
        workingDays: String? = nil,
        exhibitorType: String? = nil,
        supportType: String? = nil,
        installationNotes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.zoneId = zoneId
        self.zoneName = zoneName
        self.address = address
        self.createdAt = createdAt
        self.markedById = markedById
        self.description = description
        self.hasWhatsApp = hasWhatsApp
        self.notes = notes
        self.competition = competition
        self.status = status
        self.managerName = managerName
        self.phone = phone
        self.email = email
        self.openingHours = openingHours
        self.openingTimeFrom = openingTimeFrom
        self.openingTimeTo = openingTimeTo
        self.workingDays = workingDays
        self.exhibitorType = exhibitorType
        self.supportType = supportType
        self.installationNotes = installationNotes
    }
    
    // Computed properties
    var isActive: Bool {
        status == nil || status == "active" || status == "visitado"
    }
    
    var statusDisplayName: String {
        switch status {
        case "no_visitado": return "No visitado"
        case "visitado": return "Visitado"
        case "pendiente": return "Pendiente"
        case "active": return "Activo"
        case "inactive": return "Inactivo"
        default: return status ?? "Sin estado"
        }
    }
    
    var statusColor: String {
        switch status {
        case "visitado", "active": return "#22C55E"
        case "no_visitado": return "#6B7280"
        case "inactive": return "#EF4444"
        case "pendiente": return "#F59E0B"
        default: return "#6B7280"
        }
    }
}

// MARK: - Sale Point Update Request

struct UpdateSalePointRequest: Encodable {
    // Básico
    let name: String?
    let description: String?
    let hasWhatsApp: Bool?
    let notes: String?
    let competition: String?
    let status: String?
    
    // Contacto
    let managerName: String?
    let phone: String?
    let email: String?
    let openingTimeFrom: String?
    let openingTimeTo: String?
    let workingDays: String?
    
    // Exhibidor
    let exhibitorType: String?
    let supportType: String?
    let installationNotes: String?
    
    // Legacy (opcional)
    let address: String?
    let openingHours: String?
    
    // Usar snake_case para el backend
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case hasWhatsApp = "has_whatsapp"
        case notes
        case competition
        case status
        case managerName = "manager_name"
        case phone
        case email
        case openingTimeFrom = "opening_time_from"
        case openingTimeTo = "opening_time_to"
        case workingDays = "working_days"
        case exhibitorType = "exhibitor_type"
        case supportType = "support_type"
        case installationNotes = "installation_notes"
        case address
        case openingHours = "opening_hours"
    }
    
    // Custom encoder que omite campos nil
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Solo codificar los campos que tienen valor
        if let name = name { try container.encode(name, forKey: .name) }
        if let description = description { try container.encode(description, forKey: .description) }
        if let hasWhatsApp = hasWhatsApp { try container.encode(hasWhatsApp, forKey: .hasWhatsApp) }
        if let notes = notes { try container.encode(notes, forKey: .notes) }
        if let competition = competition { try container.encode(competition, forKey: .competition) }
        if let status = status { try container.encode(status, forKey: .status) }
        if let managerName = managerName { try container.encode(managerName, forKey: .managerName) }
        if let phone = phone { try container.encode(phone, forKey: .phone) }
        if let email = email { try container.encode(email, forKey: .email) }
        if let openingTimeFrom = openingTimeFrom { try container.encode(openingTimeFrom, forKey: .openingTimeFrom) }
        if let openingTimeTo = openingTimeTo { try container.encode(openingTimeTo, forKey: .openingTimeTo) }
        if let workingDays = workingDays { try container.encode(workingDays, forKey: .workingDays) }
        if let exhibitorType = exhibitorType { try container.encode(exhibitorType, forKey: .exhibitorType) }
        if let supportType = supportType { try container.encode(supportType, forKey: .supportType) }
        if let installationNotes = installationNotes { try container.encode(installationNotes, forKey: .installationNotes) }
        if let address = address { try container.encode(address, forKey: .address) }
        if let openingHours = openingHours { try container.encode(openingHours, forKey: .openingHours) }
    }
}

// MARK: - Zone Assignment Models

/// Representa un usuario asignado a una zona con información de rol
/// Respuesta de GET /zone-assignments/zone/:zoneId
struct ZoneUserAssignment: Decodable, Identifiable, Equatable, Hashable {
    let id: Int
    let zoneId: Int?
    let userId: Int
    let assignedAt: String?
    let user: AssignedUserDetail?
    let zone: AssignedZoneDetail?
    
    enum CodingKeys: String, CodingKey {
        case id
        case zoneId, zone_id
        case userId, user_id
        case assignedAt, assigned_at
        case user
        case zone
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        
        // userId: probar ambos formatos
        if let uid = try? container.decode(Int.self, forKey: .userId) {
            userId = uid
        } else {
            userId = try container.decode(Int.self, forKey: .user_id)
        }
        
        // zoneId: probar ambos formatos
        if let zid = try? container.decodeIfPresent(Int.self, forKey: .zoneId) {
            zoneId = zid
        } else {
            zoneId = try container.decodeIfPresent(Int.self, forKey: .zone_id)
        }
        
        // assignedAt: probar ambos formatos
        if let at = try? container.decodeIfPresent(String.self, forKey: .assignedAt) {
            assignedAt = at
        } else {
            assignedAt = try container.decodeIfPresent(String.self, forKey: .assigned_at)
        }
        
        user = try container.decodeIfPresent(AssignedUserDetail.self, forKey: .user)
        zone = try container.decodeIfPresent(AssignedZoneDetail.self, forKey: .zone)
    }
    
    struct AssignedUserDetail: Codable, Hashable {
        let id: Int
        let username: String
        let email: String?
        let role: UserRoleInfo?  // Nuevo: rol como objeto simple
        let roles: [UserRole]?   // Legacy: mantener compatibilidad
        
        struct UserRole: Codable, Hashable {
            let id: Int?
            let name: String
            let number: Int?
        }
        
        struct UserRoleInfo: Codable, Hashable {
            let number: Int?
            let name: String?
        }
        
        var roleNumber: Int? {
            role?.number ?? roles?.first?.number
        }
        
        var isSeller: Bool {
            // Primero verificar por número de rol (3 = Seller)
            if let number = roleNumber, number == 3 { return true }
            
            guard let roles = roles else { return false }
            let sellerKeywords = ["seller", "sales", "vendedor", "venta", "preventa", "preventista"]
            return roles.contains { role in
                sellerKeywords.contains { role.name.lowercased().contains($0) }
            }
        }
        
        var isDeliverer: Bool {
            // Primero verificar por número de rol (5 = Entregador)
            if let number = roleNumber, number == 5 { return true }
            
            guard let roles = roles else { return false }
            let delivererKeywords = ["deliverer", "delivery", "repartidor", "reparto", "entregador", "cadete"]
            return roles.contains { role in
                delivererKeywords.contains { role.name.lowercased().contains($0) }
            }
        }
        
        var roleDisplayName: String {
            if let roleName = role?.name, !roleName.isEmpty {
                return roleName
            }
            if isSeller { return "Vendedor" }
            if isDeliverer { return "Entregador" }
            return roles?.first?.name ?? "Sin rol"
        }
    }
    
    struct AssignedZoneDetail: Codable, Hashable {
        let id: Int
        let name: String?
    }
    
    static func == (lhs: ZoneUserAssignment, rhs: ZoneUserAssignment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Tipos de rol para filtrar usuarios
enum UserRoleType: String, CaseIterable {
    case seller = "Seller"
    case deliverer = "Entregador"
    
    var displayName: String {
        switch self {
        case .seller: return "Vendedor"
        case .deliverer: return "Entregador"
        }
    }
    
    var icon: String {
        switch self {
        case .seller: return "cart.fill"
        case .deliverer: return "truck.box.fill"
        }
    }
}

struct ZoneCount: Codable, Identifiable {
    let zoneId: Int?
    let count: Int

    var id: Int { zoneId ?? -1 }
}
