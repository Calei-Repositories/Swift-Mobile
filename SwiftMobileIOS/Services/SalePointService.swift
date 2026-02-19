import Foundation

/// Servicio para gestionar puntos de venta
final class SalePointService {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    // MARK: - Sale Points CRUD
    
    /// Obtener punto de venta por ID
    func getSalePoint(id: Int) async throws -> MarkedSalePoint {
        let endpoint = Endpoint(path: "/sale-points/\(id)", method: .get)
        return try await client.request(endpoint, responseType: MarkedSalePoint.self)
    }
    
    /// Listar puntos de venta de una zona
    func listSalePoints(zoneId: Int) async throws -> [MarkedSalePoint] {
        let queryItems = [URLQueryItem(name: "zoneId", value: String(zoneId))]
        let endpoint = Endpoint(path: "/sale-points", method: .get, queryItems: queryItems)
        return try await client.request(endpoint, responseType: [MarkedSalePoint].self)
    }
    
    /// Actualizar punto de venta
    func updateSalePoint(id: Int, request: UpdateSalePointRequest) async throws -> MarkedSalePoint {
        let endpoint = Endpoint(path: "/sale-points/\(id)", method: .patch, body: request)
        return try await client.request(endpoint, responseType: MarkedSalePoint.self)
    }
    
    /// Actualizar campos específicos de un punto de venta
    func updateSalePointFields(
        id: Int,
        name: String? = nil,
        address: String? = nil,
        hasWhatsApp: Bool? = nil,
        notes: String? = nil,
        managerName: String? = nil,
        openingHours: String? = nil,
        exhibitorType: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        status: String? = nil
    ) async throws -> MarkedSalePoint {
        let request = UpdateSalePointRequest(
            name: name,
            address: address,
            hasWhatsApp: hasWhatsApp,
            notes: notes,
            managerName: managerName,
            openingHours: openingHours,
            exhibitorType: exhibitorType,
            phone: phone,
            email: email,
            status: status
        )
        return try await updateSalePoint(id: id, request: request)
    }
}
