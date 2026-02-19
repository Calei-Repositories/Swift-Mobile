import Foundation
import CoreLocation

@MainActor
final class AddSalePointViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case saving
        case success
        case error(String)
    }
    
    @Published var state: State = .idle
    @Published var name = ""
    @Published var address = ""
    @Published var phone = ""
    @Published var email = ""
    @Published var contactName = ""
    @Published var notes = ""
    @Published var selectedStatusId: Int?
    @Published var selectedZoneId: Int?
    @Published var statuses: [SalePointStatus] = []
    @Published var zones: [Zone] = []
    @Published var useCurrentLocation = true
    @Published var manualLatitude = ""
    @Published var manualLongitude = ""
    
    let trackId: Int
    private let trackService: TrackService
    private let locationService: LocationService
    
    init(trackId: Int, trackService: TrackService = TrackService(), locationService: LocationService = .shared) {
        self.trackId = trackId
        self.trackService = trackService
        self.locationService = locationService
    }
    
    var isFormValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    var currentLocation: CLLocation? {
        locationService.currentLocation
    }
    
    func loadOptions() async {
        state = .loading
        do {
            async let statusesTask = trackService.listSalePointStatuses()
            async let zonesTask = trackService.listZones()
            
            statuses = try await statusesTask
            zones = try await zonesTask
            state = .idle
        } catch {
            // Los catálogos son opcionales
            state = .idle
        }
    }
    
    func saveSalePoint() async -> SalePoint? {
        guard isFormValid else {
            state = .error("El nombre es requerido")
            return nil
        }
        
        state = .saving
        
        // Determinar ubicación
        var latitude: Double? = nil
        var longitude: Double? = nil
        
        if useCurrentLocation, let location = currentLocation {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
        } else if !manualLatitude.isEmpty && !manualLongitude.isEmpty {
            latitude = Double(manualLatitude)
            longitude = Double(manualLongitude)
        }
        
        let request = CreateSalePointRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            contactName: contactName.isEmpty ? nil : contactName.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            statusId: selectedStatusId,
            zoneId: selectedZoneId
        )
        
        do {
            let salePoint = try await trackService.createSalePoint(trackId: trackId, salePoint: request)
            state = .success
            return salePoint
        } catch {
            state = .error(error.localizedDescription)
            return nil
        }
    }
}
