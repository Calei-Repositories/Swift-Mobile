import Foundation

// MARK: - Wrapper para respuestas paginadas del backend
struct PaginatedResponse<T: Decodable>: Decodable {
    let count: Int
    let limit: Int?
    let data: [T]
}

final class AdminService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func markedSalePointsMap(zoneId: Int?, from: String?, to: String?, markedBy: Int?, n: Double?, s: Double?, e: Double?, w: Double?, limit: Int? = nil) async throws -> [MarkedSalePoint] {
        var items: [URLQueryItem] = []
        if let zoneId { items.append(URLQueryItem(name: "zoneId", value: String(zoneId))) }
        if let from { items.append(URLQueryItem(name: "from", value: from)) }
        if let to { items.append(URLQueryItem(name: "to", value: to)) }
        if let markedBy { items.append(URLQueryItem(name: "markedBy", value: String(markedBy))) }
        if let n { items.append(URLQueryItem(name: "n", value: String(n))) }
        if let s { items.append(URLQueryItem(name: "s", value: String(s))) }
        if let e { items.append(URLQueryItem(name: "e", value: String(e))) }
        if let w { items.append(URLQueryItem(name: "w", value: String(w))) }
        // Agregar límite para obtener más puntos (por defecto el backend limita a pocos)
        items.append(URLQueryItem(name: "limit", value: String(limit ?? 50000)))

        let endpoint = Endpoint(path: "/admin/marked-sale-points/map", method: .get, queryItems: items)
        
        // El backend devuelve {count, limit, data: [...]}
        let response = try await client.request(endpoint, responseType: PaginatedResponse<MarkedSalePoint>.self)
        print("📦 API devolvió \(response.data.count) puntos de \(response.count) totales")
        return response.data
    }

    func markedSalePointsZones() async throws -> [ZoneCount] {
        let endpoint = Endpoint(path: "/admin/marked-sale-points/zones", method: .get)
        return try await client.request(endpoint, responseType: [ZoneCount].self)
    }

    func listUsersByRole(roleId: Int) async throws -> [User] {
        let endpoint = Endpoint(path: "/users/by-role", method: .get, queryItems: [URLQueryItem(name: "roleId", value: String(roleId))])
        return try await client.request(endpoint, responseType: [User].self)
    }

    func listSellersAndDeliverers() async throws -> [User] {
        let endpoint = Endpoint(path: "/users/sellers-and-deliverers", method: .get)
        return try await client.request(endpoint, responseType: [User].self)
    }

    func assignZone(zoneId: Int, userId: Int) async throws {
        let body = ZoneAssignmentRequest(zoneId: zoneId, userId: userId)
        let endpoint = Endpoint(path: "/zone-assignments", method: .post, body: body)
        
        // El backend devuelve la asignación creada, pero podemos ignorarla
        // Usar una estructura flexible para aceptar cualquier respuesta
        _ = try await client.request(endpoint, responseType: ZoneAssignmentCreateResponse.self)
        print("✅ Usuario \(userId) asignado a zona \(zoneId)")
    }
    
    // MARK: - Nuevos métodos para asignaciones según documentación del backend
    
    /// Listar usuarios por tipo de rol usando el nuevo endpoint
    /// roleId=3 para Vendedores, roleId=5 para Entregadores
    func listUsersByRoleType(_ roleType: UserRoleType) async throws -> [User] {
        let roleId = roleType == .seller ? 3 : 5
        let queryItems = [URLQueryItem(name: "roleId", value: String(roleId))]
        let endpoint = Endpoint(path: "/users/by-role", method: .get, queryItems: queryItems)
        
        do {
            let users = try await client.request(endpoint, responseType: [User].self)
            print("✅ Usuarios cargados por roleId \(roleId): \(users.count)")
            return users
        } catch {
            print("❌ Error cargando usuarios por rol: \(error)")
            throw error
        }
    }
    
    /// Listar asignaciones de una zona usando el nuevo endpoint
    /// GET /zone-assignments/zone/:zoneId
    func listZoneAssignments(zoneId: Int) async throws -> [ZoneUserAssignment] {
        let endpoint = Endpoint(path: "/zone-assignments/zone/\(zoneId)", method: .get)
        return try await client.request(endpoint, responseType: [ZoneUserAssignment].self)
    }
    
    /// Eliminar asignación de zona
    func removeZoneAssignment(assignmentId: Int) async throws {
        let endpoint = Endpoint(path: "/zone-assignments/\(assignmentId)", method: .delete)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
    }
    
    // MARK: - Marked Sale Points Management
    
    /// Actualizar un punto de venta marcado
    func updateMarkedSalePoint(id: Int, request: UpdateSalePointRequest) async throws -> MarkedSalePoint {
        let endpoint = Endpoint(path: "/admin/marked-sale-points/\(id)", method: .patch, body: request)
        return try await client.request(endpoint, responseType: MarkedSalePoint.self)
    }
}

// MARK: - Response Models

/// Respuesta al crear una asignación de zona
struct ZoneAssignmentCreateResponse: Decodable {
    let id: Int?
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
