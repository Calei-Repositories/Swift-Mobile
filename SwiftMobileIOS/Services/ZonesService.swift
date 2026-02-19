import Foundation

/// Servicio para gestionar zonas geográficas
final class ZonesService {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    // MARK: - Zones CRUD
    
    /// Listar todas las zonas
    func listZones() async throws -> [GeoZone] {
        let endpoint = Endpoint(path: "/zones", method: .get)
        
        // Intentar primero como array directo
        do {
            return try await client.request(endpoint, responseType: [GeoZone].self)
        } catch let decodingError {
            print("Error decodificando como array: \(decodingError)")
            // Si falla, intentar como objeto envuelto
            do {
                let response = try await client.request(endpoint, responseType: ZonesListResponse.self)
                return response.items
            } catch {
                print("Error decodificando como wrapper: \(error)")
                throw error
            }
        }
    }
    
    /// Obtener zona por ID
    func getZone(id: Int) async throws -> GeoZone {
        let endpoint = Endpoint(path: "/zones/\(id)", method: .get)
        
        // Intentar primero como objeto directo
        do {
            return try await client.request(endpoint, responseType: GeoZone.self)
        } catch {
            // Si falla, intentar como objeto envuelto
            let response = try await client.request(endpoint, responseType: ZoneResponse.self)
            guard let zone = response.item else {
                throw APIError.invalidResponse
            }
            return zone
        }
    }
    
    /// Crear una nueva zona
    func createZone(name: String, isDangerous: Bool, boundaryPoints: [CLLocationCoordinate2D]? = nil) async throws -> GeoZone {
        var pointsInput: [CreateZoneRequest.BoundaryPointInput]? = nil
        
        if let points = boundaryPoints, !points.isEmpty {
            pointsInput = points.enumerated().map { index, coord in
                CreateZoneRequest.BoundaryPointInput(
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    order: index
                )
            }
        }
        
        let request = CreateZoneRequest(
            name: name,
            isDangerous: isDangerous,
            boundaryPoints: pointsInput
        )
        
        let endpoint = Endpoint(path: "/zones", method: .post, body: request)
        
        do {
            return try await client.request(endpoint, responseType: GeoZone.self)
        } catch {
            let response = try await client.request(endpoint, responseType: ZoneResponse.self)
            guard let zone = response.item else {
                throw APIError.invalidResponse
            }
            return zone
        }
    }
    
    /// Actualizar una zona existente
    func updateZone(id: Int, name: String? = nil, isDangerous: Bool? = nil, isActive: Bool? = nil) async throws -> GeoZone {
        let request = UpdateZoneRequest(
            name: name,
            isDangerous: isDangerous,
            isActive: isActive
        )
        
        let endpoint = Endpoint(path: "/zones/\(id)", method: .patch, body: request)
        
        do {
            return try await client.request(endpoint, responseType: GeoZone.self)
        } catch {
            let response = try await client.request(endpoint, responseType: ZoneResponse.self)
            guard let zone = response.item else {
                throw APIError.invalidResponse
            }
            return zone
        }
    }
    
    /// Eliminar una zona
    func deleteZone(id: Int) async throws {
        let endpoint = Endpoint(path: "/zones/\(id)", method: .delete)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
    }
    
    // MARK: - Boundary Points
    
    /// Agregar puntos al perímetro de una zona
    func addBoundaryPoints(zoneId: Int, points: [CLLocationCoordinate2D]) async throws -> GeoZone {
        let pointsInput = points.enumerated().map { index, coord in
            AddBoundaryPointsRequest.BoundaryPointInput(
                latitude: coord.latitude,
                longitude: coord.longitude,
                order: index
            )
        }
        
        let request = AddBoundaryPointsRequest(points: pointsInput)
        let endpoint = Endpoint(path: "/zones/\(zoneId)/boundary-points", method: .patch, body: request)
        
        do {
            return try await client.request(endpoint, responseType: GeoZone.self)
        } catch {
            let response = try await client.request(endpoint, responseType: ZoneResponse.self)
            guard let zone = response.item else {
                throw APIError.invalidResponse
            }
            return zone
        }
    }
    
    /// Reemplazar todos los puntos del perímetro
    func setBoundaryPoints(zoneId: Int, points: [CLLocationCoordinate2D]) async throws -> GeoZone {
        // Primero actualizar la zona para limpiar puntos existentes si es necesario
        // Luego agregar los nuevos puntos
        return try await addBoundaryPoints(zoneId: zoneId, points: points)
    }
    
    // MARK: - Geographic Search
    
    /// Buscar zonas por radio (punto central + distancia)
    func searchZonesByRadius(latitude: Double, longitude: Double, radiusMeters: Double) async throws -> [GeoZone] {
        let queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(radiusMeters))
        ]
        
        let endpoint = Endpoint(path: "/zones/area", method: .get, queryItems: queryItems)
        
        do {
            return try await client.request(endpoint, responseType: [GeoZone].self)
        } catch {
            let response = try await client.request(endpoint, responseType: ZonesListResponse.self)
            return response.items
        }
    }
    
    /// Buscar zonas por bounding box
    func searchZonesByBoundingBox(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double) async throws -> [GeoZone] {
        let queryItems = [
            URLQueryItem(name: "minLat", value: String(minLat)),
            URLQueryItem(name: "maxLat", value: String(maxLat)),
            URLQueryItem(name: "minLng", value: String(minLng)),
            URLQueryItem(name: "maxLng", value: String(maxLng))
        ]
        
        let endpoint = Endpoint(path: "/zones/area", method: .get, queryItems: queryItems)
        
        do {
            return try await client.request(endpoint, responseType: [GeoZone].self)
        } catch {
            let response = try await client.request(endpoint, responseType: ZonesListResponse.self)
            return response.items
        }
    }
    
    // MARK: - Zone Assignments
    
    /// Obtener usuarios por rol específico (3=Seller, 5=Entregador)
    func getUsersByRole(roleId: Int) async throws -> [AssignableUser] {
        let queryItems = [URLQueryItem(name: "roleId", value: String(roleId))]
        let endpoint = Endpoint(path: "/users/by-role", method: .get, queryItems: queryItems)
        return try await client.request(endpoint, responseType: [AssignableUser].self)
    }
    
    /// Obtener todos los vendedores y entregadores juntos
    func getSellersAndDeliverers() async throws -> [AssignableUser] {
        let endpoint = Endpoint(path: "/users/sellers-and-deliverers", method: .get)
        return try await client.request(endpoint, responseType: [AssignableUser].self)
    }
    
    /// Obtener asignaciones de una zona específica
    func getZoneAssignments(zoneId: Int) async throws -> [ZoneAssignment] {
        let endpoint = Endpoint(path: "/zone-assignments/zone/\(zoneId)", method: .get)
        return try await client.request(endpoint, responseType: [ZoneAssignment].self)
    }
    
    /// Asignar un usuario a una zona
    func assignUserToZone(zoneId: Int, userId: Int) async throws -> ZoneAssignmentResponse {
        let request = ZoneAssignmentRequest(zoneId: zoneId, userId: userId)
        let endpoint = Endpoint(path: "/zone-assignments", method: .post, body: request)
        return try await client.request(endpoint, responseType: ZoneAssignmentResponse.self)
    }
    
    /// Eliminar una asignación por su ID
    func removeAssignment(assignmentId: Int) async throws -> RemoveAssignmentResponse {
        let endpoint = Endpoint(path: "/zone-assignments/\(assignmentId)", method: .delete)
        return try await client.request(endpoint, responseType: RemoveAssignmentResponse.self)
    }
    
    /// Listar asignaciones de una zona (método legacy - usar getZoneAssignments)
    func listZoneAssignments(zoneId: Int) async throws -> [ZoneAssignment] {
        return try await getZoneAssignments(zoneId: zoneId)
    }
}

// MARK: - Import CoreLocation for CLLocationCoordinate2D
import CoreLocation
