import Foundation

final class TrackService {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    // MARK: - Tracks
    
    /// Listar todos los recorridos del usuario
    func listTracks() async throws -> [Track] {
        let endpoint = Endpoint(path: "/tracks", method: .get)
        // El backend puede devolver array directo o wrapped
        do {
            return try await client.request(endpoint, responseType: [Track].self)
        } catch {
            let response = try await client.request(endpoint, responseType: TracksResponse.self)
            return response.items
        }
    }
    
    /// Obtener detalle de un recorrido
    func getTrack(id: Int) async throws -> Track {
        let endpoint = Endpoint(path: "/tracks/\(id)", method: .get)
        return try await client.request(endpoint, responseType: Track.self)
    }
    
    /// Crear un nuevo recorrido
    func createTrack(name: String, description: String?) async throws -> Track {
        let body = CreateTrackRequest(name: name, description: description)
        let endpoint = Endpoint(path: "/tracks", method: .post, body: body)
        return try await client.request(endpoint, responseType: Track.self)
    }
    
    /// Actualizar un recorrido
    func updateTrack(id: Int, name: String? = nil, description: String? = nil, completed: Bool? = nil) async throws -> Track {
        struct UpdateRequest: Encodable {
            let name: String?
            let description: String?
            let completed: Bool?
        }
        let body = UpdateRequest(name: name, description: description, completed: completed)
        let endpoint = Endpoint(path: "/tracks/\(id)", method: .patch, body: body)
        return try await client.request(endpoint, responseType: Track.self)
    }
    
    /// Marcar recorrido como completado
    func completeTrack(id: Int) async throws -> Track {
        return try await updateTrack(id: id, completed: true)
    }
    
    /// Eliminar un recorrido
    func deleteTrack(id: Int) async throws {
        let endpoint = Endpoint(path: "/tracks/\(id)", method: .delete)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
    }
    
    // MARK: - SubTracks (Segmentos GPS)
    
    /// Agregar un segmento GPS completo al recorrido
    /// El SubTrack contiene un array de coordenadas con timestamps
    func addSubTrack(trackId: Int, subTrack: CreateSubTrackRequest) async throws -> Track {
        let endpoint = Endpoint(path: "/tracks/\(trackId)/subtracks", method: .post, body: subTrack)
        return try await client.request(endpoint, responseType: Track.self)
    }
    
    // MARK: - Sale Points (Puntos de Venta)
    
    /// Crear un punto de venta en el recorrido
    func createSalePoint(trackId: Int, salePoint: CreateSalePointRequest) async throws -> SalePoint {
        let endpoint = Endpoint(path: "/tracks/\(trackId)/sale-points", method: .post, body: salePoint)
        return try await client.request(endpoint, responseType: SalePoint.self)
    }
    
    /// Crear un punto de venta simple (solo nombre y coordenadas)
    func createSimpleSalePoint(trackId: Int, name: String, latitude: Double, longitude: Double) async throws -> SalePoint {
        let request = CreateSalePointRequest(
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
        return try await createSalePoint(trackId: trackId, salePoint: request)
    }
    
    /// Listar puntos de venta de un recorrido
    func listSalePoints(trackId: Int) async throws -> [SalePoint] {
        let endpoint = Endpoint(path: "/tracks/\(trackId)/sale-points", method: .get)
        return try await client.request(endpoint, responseType: [SalePoint].self)
    }
    
    /// Eliminar un punto de venta
    func deleteSalePoint(trackId: Int, salePointId: Int) async throws {
        let endpoint = Endpoint(path: "/tracks/\(trackId)/sale-points/\(salePointId)", method: .delete)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
    }
    
    /// Transferir un punto de venta a otro recorrido
    func transferSalePoint(fromTrackId: Int, salePointId: Int, toTrackId: Int) async throws -> SalePoint {
        let body = TransferSalePointRequest(newTrackId: toTrackId)
        let endpoint = Endpoint(
            path: "/tracks/\(fromTrackId)/sale-points/\(salePointId)/transfer",
            method: .patch,
            body: body
        )
        return try await client.request(endpoint, responseType: SalePoint.self)
    }
    
    /// Actualizar el estado de un punto de venta
    func updateSalePointStatus(trackId: Int, salePointId: Int, statusId: Int, notes: String? = nil) async throws -> SalePoint {
        let body = UpdateSalePointStatusRequest(statusId: statusId, notes: notes)
        let endpoint = Endpoint(
            path: "/tracks/\(trackId)/sale-points/\(salePointId)/status",
            method: .patch,
            body: body
        )
        return try await client.request(endpoint, responseType: SalePoint.self)
    }
    
    // MARK: - Statuses
    
    /// Obtener estados disponibles para puntos de venta
    func listSalePointStatuses() async throws -> [SalePointStatus] {
        let endpoint = Endpoint(path: "/statuses/sale-points", method: .get)
        return try await client.request(endpoint, responseType: [SalePointStatus].self)
    }
    
    // MARK: - Zones
    
    /// Obtener zonas disponibles
    func listZones() async throws -> [Zone] {
        let endpoint = Endpoint(path: "/zones", method: .get)
        return try await client.request(endpoint, responseType: [Zone].self)
    }
}
