import Foundation
import Combine

@MainActor
final class DeliveriesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var deliveries: [Delivery] = []
    @Published var statusFilter: DeliveryStatus = .all
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties
    
    var filteredDeliveries: [Delivery] {
        if searchQuery.isEmpty {
            return deliveries
        }
        return deliveries.filter { delivery in
            delivery.displayTitle.localizedCaseInsensitiveContains(searchQuery) ||
            delivery.zone?.name.localizedCaseInsensitiveContains(searchQuery) == true
        }
    }
    
    var pendingCount: Int {
        deliveries.filter { $0.deliveryStatus == .pending }.count
    }
    
    var inProgressCount: Int {
        deliveries.filter { $0.deliveryStatus == .inProgress }.count
    }
    
    var completedCount: Int {
        deliveries.filter { $0.deliveryStatus == .completed }.count
    }

    // MARK: - Dependencies
    
    private let service: DealerService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    
    init(service: DealerService = DealerService()) {
        self.service = service
    }

    // MARK: - Actions
    
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            deliveries = try await service.deliveries(status: statusFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            deliveries = try await service.deliveries(status: statusFilter)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
