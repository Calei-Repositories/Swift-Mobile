import Foundation

@MainActor
final class AdminMarkedPointsViewModel: ObservableObject {
    @Published var points: [MarkedSalePoint] = []
    @Published var zones: [ZoneCount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: AdminService

    init(service: AdminService = AdminService()) {
        self.service = service
    }

    func loadZones() async {
        isLoading = true
        defer { isLoading = false }
        do {
            zones = try await service.markedSalePointsZones()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadPoints(zoneId: Int? = nil, from: String? = nil, to: String? = nil, markedBy: Int? = nil) async {
        isLoading = true
        defer { isLoading = false }
        do {
            points = try await service.markedSalePointsMap(zoneId: zoneId, from: from, to: to, markedBy: markedBy, n: nil, s: nil, e: nil, w: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
