import Foundation
import CoreLocation
import Combine

@MainActor
final class GPSRecordingViewModel: ObservableObject {
    enum RecordingState: Equatable {
        case idle
        case recording
        case paused
        case saving
        case error(String)
    }
    
    // MARK: - Published Properties
    
    @Published var state: RecordingState = .idle
    @Published var recordedPoints: [CLLocationCoordinate2D] = []       // Todos los puntos (previos + actuales)
    @Published var previousPoints: [CLLocationCoordinate2D] = []       // Puntos de grabaciones previas (morado)
    @Published var currentSessionPoints: [CLLocationCoordinate2D] = [] // Puntos de la sesión actual (azul)
    @Published var currentLocation: CLLocation?
    @Published var totalDistance: Double = 0
    @Published var duration: TimeInterval = 0
    @Published var showAddSalePoint = false
    @Published var salePoints: [SalePoint] = []
    @Published var pointsMarkedCount = 0
    @Published var isOnline = true
    @Published var pendingSyncCount = 0
    
    // MARK: - Properties
    
    let track: Track
    private let trackService: TrackService
    private let locationService: LocationService
    private let offlineService: OfflineSyncService
    private let notificationService: RecordingNotificationService
    
    private var lastLocation: CLLocation?
    private var timer: Timer?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0  // Tiempo acumulado en pausas
    private var pauseStartTime: Date?              // Momento en que se pausó
    private var cancellables = Set<AnyCancellable>()
    
    // Para almacenar coordenadas con timestamp (para enviar al finalizar)
    private var coordinatesWithTimestamp: [(latitude: Double, longitude: Double, timestamp: Date)] = []
    
    // MARK: - Init
    
    init(
        track: Track,
        trackService: TrackService = TrackService(),
        locationService: LocationService = .shared,
        offlineService: OfflineSyncService = .shared,
        notificationService: RecordingNotificationService = .shared
    ) {
        self.track = track
        self.trackService = trackService
        self.locationService = locationService
        self.offlineService = offlineService
        self.notificationService = notificationService
        
        setupLocationCallback()
        setupNotificationCallbacks()
        setupOfflineObserver()
        restoreStateIfNeeded()
        loadExistingSalePoints()
    }
    
    // MARK: - Setup
    
    private func setupLocationCallback() {
        locationService.onLocationUpdate = { [weak self] location in
            Task { @MainActor in
                self?.handleLocationUpdate(location)
            }
        }
    }
    
    private func setupNotificationCallbacks() {
        // Callback cuando el usuario toca "Marcar Punto" desde la notificación
        notificationService.onMarkPointRequested = { [weak self] in
            Task { @MainActor in
                await self?.markCurrentLocationAsPoint()
            }
        }
        
        // Callback cuando el usuario toca "Pausar" desde la notificación
        notificationService.onPauseRequested = { [weak self] in
            Task { @MainActor in
                self?.pauseRecording()
            }
        }
        
        // Callback cuando el usuario toca "Continuar" desde la notificación
        notificationService.onResumeRequested = { [weak self] in
            Task { @MainActor in
                self?.resumeRecording()
            }
        }
    }
    
    private func setupOfflineObserver() {
        offlineService.$isOnline
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOnline)
        
        Publishers.CombineLatest(
            offlineService.$pendingSalePointsCount,
            offlineService.$pendingSubTracksCount
        )
        .map { $0 + $1 }
        .receive(on: DispatchQueue.main)
        .assign(to: &$pendingSyncCount)
    }
    
    private func restoreStateIfNeeded() {
        guard let savedState = offlineService.currentRecordingState,
              savedState.trackId == track.id else { return }
        
        // Restaurar estado
        startTime = savedState.startTime
        totalDistance = savedState.totalDistance
        pointsMarkedCount = savedState.pointsCount
        
        // Restaurar coordenadas
        recordedPoints = savedState.recordedCoordinates.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        coordinatesWithTimestamp = savedState.recordedCoordinates.map {
            ($0.latitude, $0.longitude, $0.timestamp)
        }
        
        // Restaurar estado de grabación
        if savedState.isPaused {
            state = .paused
            notificationService.showRecordingNotification(
                trackName: track.name,
                isPaused: true,
                startTime: startTime,
                points: pointsMarkedCount
            )
        } else {
            // Reanudar grabación
            state = .recording
            locationService.startTracking()
            startTimer()
            notificationService.showRecordingNotification(
                trackName: track.name,
                isPaused: false,
                startTime: startTime,
                points: pointsMarkedCount
            )
        }
    }
    
    private func loadExistingSalePoints() {
        // Cargar distancia previa del track
        totalDistance = track.totalDistance
        
        // Cargar coordenadas existentes (polyline de grabaciones anteriores) -> MORADO
        let existingCoords = track.allCoordinates
        if !existingCoords.isEmpty {
            previousPoints = existingCoords
            recordedPoints = existingCoords // Para compatibilidad con otras partes del código
        }
        
        Task {
            do {
                salePoints = try await trackService.listSalePoints(trackId: track.id)
                pointsMarkedCount = salePoints.count
            } catch {
                // Ignorar error, se cargarán cuando haya conexión
            }
        }
    }
    
    // MARK: - Formatted Properties
    
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.2f km", totalDistance / 1000)
        }
        return String(format: "%.0f m", totalDistance)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Recording Controls
    
    func startRecording() {
        guard locationService.authorizationStatus == .authorizedWhenInUse ||
              locationService.authorizationStatus == .authorizedAlways else {
            locationService.requestPermission()
            return
        }
        
        // Solicitar permisos de notificaciones antes de iniciar
        Task {
            _ = await notificationService.requestAuthorization()
        }
        
        state = .recording
        startTime = Date()
        locationService.startTracking()
        startTimer()
        
        // Mostrar notificación de grabación
        notificationService.showRecordingNotification(
            trackName: track.name,
            isPaused: false,
            startTime: startTime,
            points: pointsMarkedCount
        )
        
        // Guardar estado
        saveRecordingState()
    }
    
    func pauseRecording() {
        state = .paused
        locationService.stopTracking()
        stopTimer()
        
        // Guardar momento de pausa
        pauseStartTime = Date()
        
        // Actualizar notificación
        notificationService.updateRecordingState(isPaused: true)
        
        // Guardar estado
        saveRecordingState()
    }
    
    func resumeRecording() {
        state = .recording
        locationService.startTracking()
        
        // Acumular tiempo pausado
        if let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
            pauseStartTime = nil
        }
        
        startTimer()
        
        // Actualizar notificación
        notificationService.updateRecordingState(isPaused: false)
        
        // Guardar estado
        saveRecordingState()
    }
    
    func togglePlayPause() {
        if state == .recording {
            pauseRecording()
        } else if state == .paused {
            resumeRecording()
        }
    }
    
    func stopRecording() async {
        state = .saving
        locationService.stopTracking()
        stopTimer()
        
        // Remover notificación
        notificationService.removeRecordingNotification()
        
        // Enviar el SubTrack completo con todas las coordenadas
        await sendSubTrack()
        
        // Limpiar estado guardado
        offlineService.clearRecordingState()
        
        state = .idle
    }
    
    /// Elimina el recorrido actual sin guardar los datos y borra los puntos ya creados
    func deleteTrackAndDismiss() async {
        state = .saving
        locationService.stopTracking()
        stopTimer()
        
        // Remover notificación
        notificationService.removeRecordingNotification()
        
        // Eliminar los puntos de venta que ya se crearon en el servidor
        for salePoint in salePoints {
            do {
                try await trackService.deleteSalePoint(trackId: track.id, salePointId: salePoint.id)
            } catch {
                print("⚠️ Error eliminando punto \(salePoint.id): \(error)")
            }
        }
        
        // Limpiar estado guardado sin enviar datos
        offlineService.clearRecordingState()
        
        // Limpiar datos locales
        recordedPoints.removeAll()
        currentSessionPoints.removeAll()
        salePoints.removeAll()
        coordinatesWithTimestamp.removeAll()
        
        state = .idle
    }
    
    // MARK: - Mark Sale Point
    
    /// Marca un punto de venta en la ubicación actual
    func markCurrentLocationAsPoint() async {
        guard let location = currentLocation else { return }
        await markLocationAsPoint(coordinate: location.coordinate)
    }
    
    /// Marca un punto de venta en una ubicación específica (seleccionada manualmente)
    func markLocationAsPoint(coordinate: CLLocationCoordinate2D) async {
        pointsMarkedCount += 1
        let pointName = "Punto \(pointsMarkedCount) - \(track.name)"
        
        if isOnline {
            do {
                let newPoint = try await trackService.createSimpleSalePoint(
                    trackId: track.id,
                    name: pointName,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                salePoints.append(newPoint)
                notificationService.showPointMarkedNotification(pointName: pointName)
            } catch {
                // Si falla, guardar offline
                savePointOffline(name: pointName, coordinate: coordinate)
            }
        } else {
            // Guardar offline
            savePointOffline(name: pointName, coordinate: coordinate)
        }
        
        // Actualizar estado guardado
        saveRecordingState()
    }
    
    private func savePointOffline(name: String, location: CLLocation) {
        savePointOffline(name: name, coordinate: location.coordinate)
    }
    
    private func savePointOffline(name: String, coordinate: CLLocationCoordinate2D) {
        offlineService.savePendingSalePoint(
            trackId: track.id,
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        notificationService.showPointMarkedNotification(pointName: "\(name) (pendiente)")
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateDuration() {
        guard let start = startTime else { return }
        // Restar el tiempo acumulado en pausas
        duration = Date().timeIntervalSince(start) - pausedDuration
    }
    
    // MARK: - Location Handling
    
    private func handleLocationUpdate(_ location: CLLocation) {
        currentLocation = location
        
        // Calcular distancia
        if let last = lastLocation {
            let segmentDistance = location.distance(from: last)
            totalDistance += segmentDistance
        }
        lastLocation = location
        
        // Agregar punto al mapa - sesión ACTUAL (azul)
        currentSessionPoints.append(location.coordinate)
        recordedPoints.append(location.coordinate) // Para compatibilidad
        
        // Guardar coordenada con timestamp para enviar al finalizar
        coordinatesWithTimestamp.append((
            location.coordinate.latitude,
            location.coordinate.longitude,
            Date()
        ))
        
        // Guardar estado cada 10 puntos para persistencia
        if currentSessionPoints.count % 10 == 0 {
            saveRecordingState()
        }
    }
    
    /// Envía el SubTrack completo al finalizar la grabación
    private func sendSubTrack() async {
        guard !coordinatesWithTimestamp.isEmpty,
              let start = startTime else { return }
        
        let endTime = Date()
        
        // Crear el SubTrack con todas las coordenadas
        let subTrack = CreateSubTrackRequest(
            routePoints: coordinatesWithTimestamp,
            startTime: start,
            endTime: endTime,
            distance: totalDistance,
            paused: false
        )
        
        do {
            _ = try await trackService.addSubTrack(trackId: track.id, subTrack: subTrack)
            print("SubTrack enviado exitosamente con \(coordinatesWithTimestamp.count) puntos")
        } catch {
            print("Error enviando SubTrack: \(error)")
            // Guardar offline para sincronizar después
            offlineService.savePendingSubTrack(
                trackId: track.id,
                subTrack: subTrack
            )
        }
    }
    
    // MARK: - State Persistence
    
    private func saveRecordingState() {
        offlineService.saveRecordingState(
            trackId: track.id,
            trackName: track.name,
            startTime: startTime ?? Date(),
            totalDistance: totalDistance,
            pointsCount: pointsMarkedCount,
            isPaused: state == .paused,
            coordinates: coordinatesWithTimestamp
        )
    }
    
    // MARK: - Permissions
    
    func requestLocationPermission() {
        locationService.requestPermission()
    }
    
    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    // MARK: - Deinit
    
    deinit {
        timer?.invalidate()
    }
}
