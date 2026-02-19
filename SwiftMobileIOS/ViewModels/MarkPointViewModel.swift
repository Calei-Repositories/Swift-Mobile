import Foundation

@MainActor
final class MarkPointViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service: DealerService

    init(service: DealerService = DealerService()) {
        self.service = service
    }

    func submit(deliveryId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard let lat = Double(latitude), let lon = Double(longitude) else {
                errorMessage = "Coordenadas inválidas"
                return
            }
            _ = try await service.markNewSalePoint(deliveryId: deliveryId, name: name, latitude: lat, longitude: lon)
            successMessage = "Punto marcado"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
