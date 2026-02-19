import Foundation

final class DealerService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // MARK: - Deliveries

    func deliveries(status: DeliveryStatus = .all) async throws -> [Delivery] {
        let endpoint = Endpoint(
            path: "/dealer/deliveries",
            method: .get,
            queryItems: [URLQueryItem(name: "status", value: status.rawValue)]
        )
        return try await client.request(endpoint, responseType: [Delivery].self)
    }

    func deliveryDetail(deliveryId: Int) async throws -> Delivery {
        let endpoint = Endpoint(path: "/dealer/deliveries/\(deliveryId)", method: .get)
        return try await client.request(endpoint, responseType: Delivery.self)
    }

    func deliveryItems(deliveryId: Int) async throws -> [DeliveryItem] {
        let endpoint = Endpoint(path: "/dealer/deliveries/\(deliveryId)/items", method: .get)
        return try await client.request(endpoint, responseType: [DeliveryItem].self)
    }

    // MARK: - Delivery Items

    func deliveryItemDetail(itemId: Int) async throws -> DeliveryItemDetail {
        let endpoint = Endpoint(path: "/dealer/delivery-items/\(itemId)", method: .get)
        return try await client.request(endpoint, responseType: DeliveryItemDetail.self)
    }

    func updateDeliveryItem(
        itemId: Int,
        status: ItemStatus,
        items: [DeliveryItemLine]?,
        amount: Double?,
        note: String?
    ) async throws {
        let body = UpdateDeliveryItemRequest(
            status: status.rawValue,
            items: items,
            amount: amount,
            note: note
        )
        let endpoint = Endpoint(path: "/dealer/delivery-items/\(itemId)", method: .patch, body: body)
        _ = try await client.request(endpoint, responseType: EmptyResponse.self)
    }

    // MARK: - Print

    func printOrderTicket(orderId: Int) async throws -> PrintTicketResponse {
        let endpoint = Endpoint(path: "/dealer/orders/\(orderId)/print", method: .post)
        return try await client.request(endpoint, responseType: PrintTicketResponse.self)
    }

    // MARK: - Products

    func searchProducts(query: String, limit: Int = 20) async throws -> [Product] {
        let endpoint = Endpoint(
            path: "/dealer/products",
            method: .get,
            queryItems: [
                URLQueryItem(name: "search", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
        return try await client.request(endpoint, responseType: [Product].self)
    }

    // MARK: - Map

    func deliveryMapOverlay(
        deliveryId: Int,
        bounds: (north: Double, south: Double, east: Double, west: Double)
    ) async throws -> DeliveryMapOverlay {
        let endpoint = Endpoint(
            path: "/dealer/deliveries/\(deliveryId)/map-overlay",
            method: .get,
            queryItems: [
                URLQueryItem(name: "n", value: String(bounds.north)),
                URLQueryItem(name: "s", value: String(bounds.south)),
                URLQueryItem(name: "e", value: String(bounds.east)),
                URLQueryItem(name: "w", value: String(bounds.west))
            ]
        )
        return try await client.request(endpoint, responseType: DeliveryMapOverlay.self)
    }

    // MARK: - Mark New Sale Point

    func markNewSalePoint(
        deliveryId: Int,
        name: String,
        latitude: Double,
        longitude: Double
    ) async throws -> MarkedSalePoint {
        let body = MarkNewSalePointRequest(name: name, latitude: latitude, longitude: longitude)
        let endpoint = Endpoint(
            path: "/dealer/deliveries/\(deliveryId)/mark-new-sale-point",
            method: .post,
            body: body
        )
        return try await client.request(endpoint, responseType: MarkedSalePoint.self)
    }
}
