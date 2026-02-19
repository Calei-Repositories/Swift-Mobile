import Foundation
import MapKit

@MainActor
final class DeliveryDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var delivery: Delivery?
    @Published var items: [DeliveryItem] = []
    @Published var mapPoints: [MapDeliveryPoint] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var selectedItemId: Int?
    
    // MARK: - Computed Properties
    
    var sortedItems: [DeliveryItem] {
        items.sorted { ($0.routeOrder ?? 999) < ($1.routeOrder ?? 999) }
    }
    
    var pendingItems: [DeliveryItem] {
        items.filter { $0.itemStatus == .pending }
    }
    
    var completedItems: [DeliveryItem] {
        items.filter { $0.itemStatus == .completed }
    }
    
    var postponedItems: [DeliveryItem] {
        items.filter { $0.itemStatus == .postponeRescue || $0.itemStatus == .postponeNextWeek }
    }
    
    var itemCoordinates: [CLLocationCoordinate2D] {
        items.compactMap { $0.coordinate }
    }
    
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        let completed = Double(completedItems.count)
        return completed / Double(items.count)
    }

    // MARK: - Dependencies
    
    private let service: DealerService
    private let deliveryId: Int

    init(deliveryId: Int, service: DealerService = DealerService()) {
        self.deliveryId = deliveryId
        self.service = service
    }

    // MARK: - Actions
    
    func load() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            async let deliveryTask = service.deliveryDetail(deliveryId: deliveryId)
            async let itemsTask = service.deliveryItems(deliveryId: deliveryId)
            
            self.delivery = try await deliveryTask
            self.items = try await itemsTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            async let deliveryTask = service.deliveryDetail(deliveryId: deliveryId)
            async let itemsTask = service.deliveryItems(deliveryId: deliveryId)
            
            self.delivery = try await deliveryTask
            self.items = try await itemsTask
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMapOverlay(region: MKCoordinateRegion) async {
        let bounds = (
            north: region.center.latitude + region.span.latitudeDelta / 2,
            south: region.center.latitude - region.span.latitudeDelta / 2,
            east: region.center.longitude + region.span.longitudeDelta / 2,
            west: region.center.longitude - region.span.longitudeDelta / 2
        )
        
        do {
            let overlay = try await service.deliveryMapOverlay(deliveryId: deliveryId, bounds: bounds)
            mapPoints = overlay.points + (overlay.ghosts ?? [])
        } catch {
            print("Error loading map overlay: \(error)")
        }
    }
}
