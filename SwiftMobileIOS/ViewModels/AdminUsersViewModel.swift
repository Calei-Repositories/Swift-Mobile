import Foundation

@MainActor
final class AdminUsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: AdminService

    init(service: AdminService = AdminService()) {
        self.service = service
    }

    func loadByRole(roleId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await service.listUsersByRole(roleId: roleId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSellersAndDeliverers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await service.listSellersAndDeliverers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func assignZone(zoneId: Int, userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.assignZone(zoneId: zoneId, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
