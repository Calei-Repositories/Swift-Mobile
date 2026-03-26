import Foundation
import CoreLocation

final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var trackingError: String?
    
    // Callback para enviar ubicaciones
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    private var lastSentLocation: CLLocation?
    private let minimumDistance: CLLocationDistance = 10 // metros
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistance
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
        
        // Solicitar una ubicación inicial para tener disponible al abrir vistas
        requestSingleLocation()
    }
    
    /// Solicita una única actualización de ubicación (sin tracking continuo)
    func requestSingleLocation() {
        DLog("📍 requestSingleLocation llamado, authStatus:", authorizationStatus.rawValue)
        
        // Si no tenemos permisos, intentar solicitar
        if authorizationStatus == .notDetermined {
            DLog("📍 Permisos no determinados, solicitando...")
            requestPermission()
            return
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            DLog("📍 Sin permisos de ubicación")
            return
        }
        
        DLog("📍 Solicitando ubicación única...")
        locationManager.requestLocation()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            trackingError = "Permisos de ubicación no otorgados"
            return
        }
        
        isTracking = true
        trackingError = nil
        lastSentLocation = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> CLLocation? {
        return currentLocation
    }
    
    private func shouldSendLocation(_ newLocation: CLLocation) -> Bool {
        guard let last = lastSentLocation else { return true }
        return newLocation.distance(from: last) >= minimumDistance
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            // Cuando se otorgan permisos, solicitar ubicación inicial automáticamente
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                // Solo si no tenemos ubicación aún
                if self.currentLocation == nil {
                    DLog("📍 Permisos de ubicación otorgados, solicitando ubicación inicial...")
                    self.locationManager.requestLocation()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let shouldSend = isTracking && shouldSendLocation(location)
        
        Task { @MainActor in
            let isFirstLocation = self.currentLocation == nil
            self.currentLocation = location
            
            if isFirstLocation {
                DLog("📍 Primera ubicación obtenida:", location.coordinate.latitude, location.coordinate.longitude)
            }
            
            if shouldSend {
                self.lastSentLocation = location
                self.onLocationUpdate?(location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let errorMessage = error.localizedDescription
        DLog("📍 Error de ubicación:", errorMessage)
        Task { @MainActor in
            self.trackingError = errorMessage
        }
    }
}
