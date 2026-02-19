import Foundation

@MainActor
final class CreateTrackViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case creating
        case success(Int) // trackId
        case error(String)
    }
    
    @Published var state: State = .idle
    @Published var name = ""
    @Published var description = ""
    
    private let trackService: TrackService
    
    init(trackService: TrackService = TrackService()) {
        self.trackService = trackService
    }
    
    var isFormValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }
    
    func createTrack() async -> Track? {
        guard isFormValid else {
            state = .error("El nombre debe tener al menos 3 caracteres")
            return nil
        }
        
        state = .creating
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
            let track = try await trackService.createTrack(
                name: trimmedName,
                description: trimmedDesc.isEmpty ? nil : trimmedDesc
            )
            state = .success(track.id)
            return track
        } catch {
            state = .error(error.localizedDescription)
            return nil
        }
    }
}
