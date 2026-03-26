import Foundation
import CoreLocation

@MainActor
final class VisitPointViewModel: ObservableObject {
    @Published var deliveries: [Delivery] = []
    @Published var selectedDeliveryId: Int?
    @Published var items: [DeliveryItem] = []
    @Published var loading = false
    @Published var submittingItemIds: Set<Int> = []
    @Published var arrivedItemIds: Set<Int> = []
    @Published var feedbackMessage: String?
    @Published var errorMessage: String?

    private let dealerService: DealerService
    private let locationService: LocationService
    private let isoFormatter = ISO8601DateFormatter()

    init(dealerService: DealerService = DealerService(), locationService: LocationService = .shared) {
        self.dealerService = dealerService
        self.locationService = locationService
        self.isoFormatter.formatOptions = [.withInternetDateTime]
    }

    var sortedItems: [DeliveryItem] {
        items.sorted { ($0.routeOrder ?? Int.max) < ($1.routeOrder ?? Int.max) }
    }

    func loadInitial() async {
        loading = true
        errorMessage = nil
        feedbackMessage = nil
        defer { loading = false }

        do {
            let all = try await dealerService.deliveries(status: .all)
            let prioritized = all.filter { delivery in
                delivery.deliveryStatus == .inProgress || delivery.deliveryStatus == .pending
            }
            deliveries = prioritized.isEmpty ? all : prioritized

            if selectedDeliveryId == nil {
                selectedDeliveryId = deliveries.first?.id
            }

            if let deliveryId = selectedDeliveryId {
                items = try await dealerService.deliveryItems(deliveryId: deliveryId)
            } else {
                items = []
            }
        } catch {
            errorMessage = "No se pudieron cargar los puntos para visitar."
        }
    }

    func selectDelivery(_ deliveryId: Int) async {
        selectedDeliveryId = deliveryId
        loading = true
        errorMessage = nil
        defer { loading = false }

        do {
            items = try await dealerService.deliveryItems(deliveryId: deliveryId)
        } catch {
            errorMessage = "No se pudieron cargar los pedidos del reparto seleccionado."
        }
    }

    func arrived(item: DeliveryItem) async {
        guard !submittingItemIds.contains(item.id) else { return }
        submittingItemIds.insert(item.id)
        feedbackMessage = nil
        errorMessage = nil

        let location = locationService.currentLocation
        if location == nil {
            locationService.requestSingleLocation()
        }

        let timestamp = isoFormatter.string(from: Date())

        do {
            try await dealerService.registerArrival(
                orderId: item.id,
                timestamp: timestamp,
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude
            )
            arrivedItemIds.insert(item.id)
            feedbackMessage = "Llegada registrada en \(item.displayName)."
        } catch {
            errorMessage = "No se pudo registrar la llegada. Podés continuar y reintentar."
        }

        submittingItemIds.remove(item.id)
    }
}
