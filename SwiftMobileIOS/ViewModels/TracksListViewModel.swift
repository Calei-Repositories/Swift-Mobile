import Foundation

@MainActor
final class TracksListViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    @Published var state: State = .idle
    @Published var tracks: [Track] = []
    
    private let trackService: TrackService
    
    init(trackService: TrackService = TrackService()) {
        self.trackService = trackService
    }
    
    /// Obtiene el recorrido activo (no completado) si existe
    var activeTrack: Track? {
        tracks.first { $0.isActive }
    }
    
    /// Indica si hay un recorrido activo
    var hasActiveTrack: Bool {
        activeTrack != nil
    }
    
    func loadTracks() async {
        state = .loading
        do {
            tracks = try await trackService.listTracks()
            // Ordenar por fecha de última actualización (más recientes primero)
            // Esto asegura que el último recorrido grabado aparezca arriba
            sortTracksByLastActivity()
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    /// Ordena los tracks por última actividad (updatedAt > createdAt)
    private func sortTracksByLastActivity() {
        tracks.sort { track1, track2 in
            let date1 = track1.updatedAt ?? track1.createdAt ?? ""
            let date2 = track2.updatedAt ?? track2.createdAt ?? ""
            return date1 > date2
        }
    }
    
    /// Reordena la lista después de una grabación
    func reorderTracksAfterRecording() {
        sortTracksByLastActivity()
    }
    
    func deleteTrack(_ track: Track) async {
        do {
            try await trackService.deleteTrack(id: track.id)
            tracks.removeAll { $0.id == track.id }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func completeTrack(_ track: Track) async {
        do {
            let updatedTrack = try await trackService.completeTrack(id: track.id)
            if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                tracks[index] = updatedTrack
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
