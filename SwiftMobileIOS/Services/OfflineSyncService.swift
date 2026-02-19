import Foundation
import Network
import Combine

/// Servicio para manejar la sincronización offline de datos
final class OfflineSyncService: ObservableObject {
    static let shared = OfflineSyncService()
    
    // MARK: - Published Properties
    
    @Published private(set) var isOnline = true
    @Published private(set) var pendingSalePointsCount = 0
    @Published private(set) var pendingSubTracksCount = 0
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var currentRecordingState: RecordingState?
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.calei.networkmonitor")
    private let trackService = TrackService()
    
    private let pendingSalePointsKey = "pending_sale_points"
    private let pendingSubTracksKey = "pending_subtracks"
    private let recordingStateKey = "recording_state"
    private let lastSyncKey = "last_sync_date"
    
    private var syncTask: Task<Void, Never>?
    
    // MARK: - Init
    
    private init() {
        startNetworkMonitoring()
        loadPendingCounts()
        loadRecordingState()
    }
    
    deinit {
        monitor.cancel()
        syncTask?.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = !(self?.isOnline ?? true)
                self?.isOnline = path.status == .satisfied
                
                // Si volvimos a estar online, intentar sincronizar
                if wasOffline && path.status == .satisfied {
                    self?.syncPendingData()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    // MARK: - Sale Points Offline Storage
    
    /// Guarda un punto de venta para sincronizar después
    func savePendingSalePoint(trackId: Int, name: String, latitude: Double, longitude: Double) {
        var pending = loadPendingSalePoints()
        let newPoint = PendingSalePoint(
            trackId: trackId,
            name: name,
            latitude: latitude,
            longitude: longitude
        )
        pending.append(newPoint)
        savePendingSalePoints(pending)
        
        let count = pending.count
        Task { @MainActor in
            self.pendingSalePointsCount = count
        }
        
        // Intentar sincronizar si hay conexión
        if isOnline {
            syncPendingData()
        }
    }
    
    /// Carga los puntos de venta pendientes
    private func loadPendingSalePoints() -> [PendingSalePoint] {
        guard let data = UserDefaults.standard.data(forKey: pendingSalePointsKey),
              let points = try? JSONDecoder().decode([PendingSalePoint].self, from: data) else {
            return []
        }
        return points
    }
    
    /// Guarda los puntos de venta pendientes
    private func savePendingSalePoints(_ points: [PendingSalePoint]) {
        if let data = try? JSONEncoder().encode(points) {
            UserDefaults.standard.set(data, forKey: pendingSalePointsKey)
        }
    }
    
    // MARK: - SubTracks Offline Storage
    
    /// Guarda un subtrack completo para sincronizar después
    func savePendingSubTrack(trackId: Int, subTrack: CreateSubTrackRequest) {
        var pending = loadPendingSubTracks()
        let newSubTrack = PendingSubTrack(trackId: trackId, subTrack: subTrack)
        pending.append(newSubTrack)
        savePendingSubTracks(pending)
        
        let count = pending.count
        Task { @MainActor in
            self.pendingSubTracksCount = count
        }
        
        // Intentar sincronizar si hay conexión
        if isOnline {
            syncPendingData()
        }
    }
    
    /// Carga los subtracks pendientes
    private func loadPendingSubTracks() -> [PendingSubTrack] {
        guard let data = UserDefaults.standard.data(forKey: pendingSubTracksKey),
              let tracks = try? JSONDecoder().decode([PendingSubTrack].self, from: data) else {
            return []
        }
        return tracks
    }
    
    /// Guarda los subtracks pendientes
    private func savePendingSubTracks(_ tracks: [PendingSubTrack]) {
        if let data = try? JSONEncoder().encode(tracks) {
            UserDefaults.standard.set(data, forKey: pendingSubTracksKey)
        }
    }
    
    // MARK: - Recording State Persistence
    
    /// Guarda el estado de grabación actual para restaurar si la app se cierra
    func saveRecordingState(
        trackId: Int,
        trackName: String,
        startTime: Date,
        totalDistance: Double,
        pointsCount: Int,
        isPaused: Bool,
        coordinates: [(latitude: Double, longitude: Double, timestamp: Date)]
    ) {
        let storedCoords = coordinates.map { coord in
            RecordingState.StoredCoordinate(
                latitude: coord.latitude,
                longitude: coord.longitude,
                timestamp: coord.timestamp
            )
        }
        
        let state = RecordingState(
            trackId: trackId,
            trackName: trackName,
            startTime: startTime,
            totalDistance: totalDistance,
            pointsCount: pointsCount,
            isPaused: isPaused,
            recordedCoordinates: storedCoords
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: recordingStateKey)
            Task { @MainActor in
                self.currentRecordingState = state
            }
        }
    }
    
    /// Carga el estado de grabación guardado
    func loadRecordingState() {
        guard let data = UserDefaults.standard.data(forKey: recordingStateKey),
              let state = try? JSONDecoder().decode(RecordingState.self, from: data) else {
            currentRecordingState = nil
            return
        }
        currentRecordingState = state
    }
    
    /// Limpia el estado de grabación (cuando se termina de grabar)
    func clearRecordingState() {
        UserDefaults.standard.removeObject(forKey: recordingStateKey)
        Task { @MainActor in
            self.currentRecordingState = nil
        }
    }
    
    /// Verifica si hay una grabación activa
    var hasActiveRecording: Bool {
        currentRecordingState != nil
    }
    
    // MARK: - Synchronization
    
    /// Sincroniza todos los datos pendientes con el servidor
    func syncPendingData() {
        guard isOnline, !isSyncing else { return }
        
        syncTask?.cancel()
        syncTask = Task { @MainActor in
            isSyncing = true
            
            // Sincronizar puntos de venta
            await syncPendingSalePoints()
            
            // Sincronizar subtracks
            await syncPendingSubTracks()
            
            isSyncing = false
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
        }
    }
    
    private func syncPendingSalePoints() async {
        let pendingItems = loadPendingSalePoints()
        var synced: [UUID] = []
        var failedIds: [UUID] = []
        
        for point in pendingItems where point.syncStatus == .pending || point.syncStatus == .failed {
            do {
                _ = try await trackService.createSalePoint(
                    trackId: point.trackId,
                    salePoint: point.toRequest()
                )
                synced.append(point.id)
            } catch {
                // Marcar como fallido para reintentar después
                failedIds.append(point.id)
            }
        }
        
        // Crear lista actualizada
        var updatedPending = pendingItems
        
        // Actualizar status de los fallidos
        for id in failedIds {
            if let index = updatedPending.firstIndex(where: { $0.id == id }) {
                updatedPending[index].syncStatus = .failed
            }
        }
        
        // Eliminar los sincronizados
        updatedPending.removeAll { synced.contains($0.id) }
        savePendingSalePoints(updatedPending)
        
        let finalCount = updatedPending.count
        await MainActor.run {
            pendingSalePointsCount = finalCount
        }
    }
    
    private func syncPendingSubTracks() async {
        let pendingItems = loadPendingSubTracks()
        var synced: [UUID] = []
        var failedIds: [UUID] = []
        
        for track in pendingItems where track.syncStatus == .pending || track.syncStatus == .failed {
            do {
                _ = try await trackService.addSubTrack(
                    trackId: track.trackId,
                    subTrack: track.subTrack
                )
                synced.append(track.id)
            } catch {
                // Marcar como fallido para reintentar después
                failedIds.append(track.id)
            }
        }
        
        // Crear lista actualizada
        var updatedPending = pendingItems
        
        // Actualizar status de los fallidos
        for id in failedIds {
            if let index = updatedPending.firstIndex(where: { $0.id == id }) {
                updatedPending[index].syncStatus = .failed
            }
        }
        
        // Eliminar los sincronizados
        updatedPending.removeAll { synced.contains($0.id) }
        savePendingSubTracks(updatedPending)
        
        let finalCount = updatedPending.count
        await MainActor.run {
            pendingSubTracksCount = finalCount
        }
    }
    
    // MARK: - Helpers
    
    private func loadPendingCounts() {
        pendingSalePointsCount = loadPendingSalePoints().count
        pendingSubTracksCount = loadPendingSubTracks().count
        
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = lastSync
        }
    }
    
    /// Total de elementos pendientes de sincronizar
    var totalPendingCount: Int {
        pendingSalePointsCount + pendingSubTracksCount
    }
    
    /// Indica si hay datos pendientes de sincronizar
    var hasPendingData: Bool {
        totalPendingCount > 0
    }
}
