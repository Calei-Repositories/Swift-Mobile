import Foundation

@MainActor
final class TrackDetailViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    @Published var state: State = .idle
    @Published var track: Track?
    @Published var allTracks: [Track] = [] // Para la lista de transferencia
    @Published private var loadedSalePoints: [SalePoint] = [] // SalePoints cargados separadamente
    
    private let trackId: Int
    private let trackService: TrackService
    
    init(trackId: Int, trackService: TrackService = TrackService()) {
        self.trackId = trackId
        self.trackService = trackService
    }
    
    var coordinates: [(latitude: Double, longitude: Double)] {
        guard let coords = track?.allCoordinates else { return [] }
        return coords.map { ($0.latitude, $0.longitude) }
    }
    
    var salePoints: [SalePoint] {
        // Priorizar los cargados separadamente, luego los del track
        if !loadedSalePoints.isEmpty {
            return loadedSalePoints
        }
        return track?.salePoints ?? []
    }
    
    var formattedDistance: String {
        guard let distance = track?.totalDistance else { return "0 m" }
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }
    
    var pointsCount: Int {
        salePoints.count
    }
    
    var segmentsCount: Int {
        track?.subTracks?.count ?? 0
    }
    
    func loadTrack() async {
        state = .loading
        do {
            track = try await trackService.getTrack(id: trackId)
            // Cargar salePoints de forma separada
            loadedSalePoints = try await trackService.listSalePoints(trackId: trackId)
            // También cargar la lista de tracks para transferencias
            allTracks = try await trackService.listTracks()
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    /// Elimina un punto de venta del recorrido
    func deleteSalePoint(_ salePoint: SalePoint) async {
        do {
            try await trackService.deleteSalePoint(trackId: trackId, salePointId: salePoint.id)
            // Recargar el track para actualizar la lista
            await loadTrack()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    /// Transfiere un punto de venta a otro recorrido
    func transferSalePoint(_ salePoint: SalePoint, toTrackId: Int) async {
        do {
            _ = try await trackService.transferSalePoint(
                fromTrackId: trackId,
                salePointId: salePoint.id,
                toTrackId: toTrackId
            )
            // Recargar el track para actualizar la lista
            await loadTrack()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    /// Obtiene la lista de tracks disponibles para transferir (excluyendo el actual)
    var availableTracksForTransfer: [Track] {
        allTracks.filter { $0.id != trackId }
    }
}
