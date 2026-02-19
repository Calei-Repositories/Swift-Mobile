import Foundation

@MainActor
final class ProductSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var limit: Int = 10
    @Published var results: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: DealerService

    init(service: DealerService = DealerService()) {
        self.service = service
    }

    func search() async {
        guard !query.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            results = try await service.searchProducts(query: query, limit: limit)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
