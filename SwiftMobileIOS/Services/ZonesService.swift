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
            pointsInput = points.enumerated().map { _, coord in
                CreateZoneRequest.BoundaryPointInput(
                    lat: Double(round(coord.latitude * 1_00000) / 1_00000),
                    lng: Double(round(coord.longitude * 1_00000) / 1_00000)
                )
            }
        }

        // First attempt: include isDangerous in POST to admin endpoint per backend guide
        let requestWithIsDangerous = CreateZoneRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            boundaryPoints: pointsInput,
            isDangerous: isDangerous ? true : nil
        )

        // Log payload for debugging
        do {
            let payloadData = try JSONEncoder().encode(requestWithIsDangerous)
            if let payloadString = String(data: payloadData, encoding: .utf8) {
                DLog("CreateZone payload (with isDangerous):", payloadString)
                print("CreateZone payload (with isDangerous):")
                print(payloadString)
            }
        } catch {
            DLog("Failed to encode CreateZoneRequest (with isDangerous) for logging:", error)
            print("CreateZone payload: <failed to encode payload: \(error)>")
        }

        // Helper: extract HTTP status code from thrown Error (unwrap APIError.other)
        func httpStatusCode(from error: Error) -> Int? {
            // If APIError.other contains an underlying NSError, return its code
            if let apiErr = error as? APIError {
                switch apiErr {
                case .other(let underlying):
                    return (underlying as NSError).code
                default:
                    return nil
                }
            }
            return (error as NSError).code
        }

        // Helper to attempt POST to a given path with a CreateZoneRequest body
        func attemptCreate(path: String, body: CreateZoneRequest) async throws -> GeoZone {
            let ep = Endpoint(path: path, method: .post, body: body)
            do {
                let created: GeoZone = try await client.request(ep, responseType: GeoZone.self)
                return created
            } catch {
                // If the server returned a wrapped response shape, try parsing that as well
                if let code = httpStatusCode(from: error), code != 404 {
                    // For non-404 errors we'll still attempt to decode wrapper as a last try
                    do {
                        let resp = try await client.request(ep, responseType: ZoneResponse.self)
                        if let z = resp.item { return z }
                    } catch {
                        // fallthrough to rethrow original
                    }
                }
                throw error
            }
        }

        // Try admin path first, then fallback to non-admin path on 404
        let adminPath = "/admin/zones"
        let publicPath = "/zones"

        do {
            let created = try await attemptCreate(path: adminPath, body: requestWithIsDangerous)
            DLog("CreateZone success: id=\(created.id), name=\(created.name)")
            return created
        } catch {
            DLog("CreateZone POST (with isDangerous) failed:", error)

            // If the error was a 404, attempt the same payload on the non-admin path
            if let code = httpStatusCode(from: error), code == 404 {
                do {
                    let created = try await attemptCreate(path: publicPath, body: requestWithIsDangerous)
                    DLog("CreateZone success on public path: id=\(created.id), name=\(created.name)")
                    return created
                } catch {
                    DLog("CreateZone on public path failed:", error)
                    // continue to other fallbacks below
                }
            }

            DLog("Attempting fallback create without isDangerous (trying admin then public):")

            let requestWithoutFlags = CreateZoneRequest(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                boundaryPoints: pointsInput,
                isDangerous: nil
            )

            // Log fallback payload
            do {
                let payloadData = try JSONEncoder().encode(requestWithoutFlags)
                if let payloadString = String(data: payloadData, encoding: .utf8) {
                    DLog("CreateZone payload (without flags):", payloadString)
                    print("CreateZone payload (without flags):")
                    print(payloadString)
                }
            } catch {
                DLog("Failed to encode CreateZoneRequest (without flags) for logging:", error)
            }

            // Try admin without flags
            do {
                let created = try await attemptCreate(path: adminPath, body: requestWithoutFlags)
                DLog("CreateZone fallback success (admin no flags): id=\(created.id), name=\(created.name)")
                if isDangerous {
                    let updated = try await updateZone(id: created.id, name: nil, isDangerous: true, isActive: nil)
                    return updated
                }
                return created
            } catch {
                if let code2 = httpStatusCode(from: error), code2 == 404 {
                    // Try public path without flags
                    do {
                        let created = try await attemptCreate(path: publicPath, body: requestWithoutFlags)
                        DLog("CreateZone fallback success (public no flags): id=\(created.id), name=\(created.name)")
                        if isDangerous {
                            let updated = try await updateZone(id: created.id, name: nil, isDangerous: true, isActive: nil)
                            return updated
                        }
                        return created
                    } catch {
                        DLog("CreateZone public fallback failed:", error)
                        throw error
                    }
                }

                // Try wrapped response shape on admin path as a last resort
                do {
                    let resp = try await client.request(Endpoint(path: adminPath, method: .post, body: requestWithoutFlags), responseType: ZoneResponse.self)
                    if let zone = resp.item {
                        DLog("CreateZone wrapped fallback success: id=\(zone.id), name=\(zone.name)")
                        if isDangerous {
                            let updated = try await updateZone(id: zone.id, name: nil, isDangerous: true, isActive: nil)
                            return updated
                        }
                        return zone
                    }
                } catch {
                    DLog("CreateZone wrapped fallback failed:", error)
                }

                DLog("CreateZone completely failed:", error)
                throw error
            }
        }
    }
    
    /// Actualizar una zona existente
    func updateZone(id: Int, name: String? = nil, isDangerous: Bool? = nil, isActive: Bool? = nil) async throws -> GeoZone {
        // Send isDangerous in PATCH per backend contract (admin path)
        let request = UpdateZoneRequest(
            name: name,
            isDangerous: isDangerous,
            isActive: isActive
        )

        // Debug: log update payload
        do {
            let payloadData = try JSONEncoder().encode(request)
            if let payloadString = String(data: payloadData, encoding: .utf8) {
                DLog("UpdateZone payload:", payloadString)
                print("UpdateZone payload:")
                print(payloadString)
            }
        } catch {
            DLog("Failed to encode UpdateZoneRequest for logging:", error)
            print("UpdateZone payload: <failed to encode payload: \(error)>")
        }

        // Try admin path first, then fallback to public path if server returns 404
        let adminPath = "/admin/zones/\(id)"
        let publicPath = "/zones/\(id)"

        func httpStatusCode(from error: Error) -> Int? {
            if let apiErr = error as? APIError {
                switch apiErr {
                case .other(let underlying):
                    return (underlying as NSError).code
                default:
                    return nil
                }
            }
            return (error as NSError).code
        }

        do {
            let endpoint = Endpoint(path: adminPath, method: .patch, body: request)
            let updated: GeoZone = try await client.request(endpoint, responseType: GeoZone.self)
            DLog("UpdateZone returned isDangerous:", String(describing: updated.isDangerous))
            if let data = try? JSONEncoder().encode(updated), let s = String(data: data, encoding: .utf8) {
                DLog("UpdateZone response object:", s)
                print("UpdateZone response:")
                print(s)
            }
            return updated
        } catch {
            DLog("UpdateZone admin path failed:", error)
            if let code = httpStatusCode(from: error), code == 404 {
                // try public path
                do {
                    let endpoint = Endpoint(path: publicPath, method: .patch, body: request)
                    let updated: GeoZone = try await client.request(endpoint, responseType: GeoZone.self)
                    DLog("UpdateZone succeeded on public path")
                    return updated
                } catch {
                    DLog("UpdateZone public path failed:", error)
                    throw error
                }
            }
            throw error
        }
    }

    /// Attempt to set a single flag via dedicated endpoint POST /zones/{id}/flags
    private func setZoneFlag(zoneId: Int, flag: String, value: Bool) async throws {
        struct SetFlagRequest: Codable {
            let flag: String
            let value: Bool
        }

        let req = SetFlagRequest(flag: flag, value: value)
        let endpointPost = Endpoint(path: "/zones/\(zoneId)/flags", method: .post, body: req)

        do {
            // Try POST /zones/{id}/flags first
            _ = try await client.request(endpointPost, responseType: EmptyResponse.self)
            return
        } catch {
            DLog("setZoneFlag POST failed, will try PATCH fallback:", error)
            // Try PATCH /zones/{id}/flags with simple body {"dangerous": true}
            struct PatchFlagBody: Codable {
                let dangerous: Bool
            }
            let patchBody = PatchFlagBody(dangerous: value)
            let endpointPatch = Endpoint(path: "/zones/\(zoneId)/flags", method: .patch, body: patchBody)
            do {
                _ = try await client.request(endpointPatch, responseType: EmptyResponse.self)
                return
            } catch {
                DLog("setZoneFlag PATCH fallback failed:", error)
                throw error
            }
        }
    }
    
    /// Eliminar una zona
    func deleteZone(id: Int) async throws {
        func httpStatusCode(from error: Error) -> Int? {
            if let apiErr = error as? APIError {
                switch apiErr {
                case .other(let underlying): return (underlying as NSError).code
                default: return nil
                }
            }
            return (error as NSError).code
        }

        // Try the public path first (staging exposes /zones, not /admin/zones)
        do {
            let endpoint = Endpoint(path: "/zones/\(id)", method: .delete)
            _ = try await client.request(endpoint, responseType: EmptyResponse.self)
            return
        } catch {
            DLog("DeleteZone public path failed, trying admin:", error)
            // If not a 404/405, rethrow immediately (no point retrying a different path)
            guard let code = httpStatusCode(from: error), code == 404 || code == 405 else {
                throw error
            }
        }

        // Fallback: admin path
        let endpoint = Endpoint(path: "/admin/zones/\(id)", method: .delete)
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
