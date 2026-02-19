import Foundation
import CoreLocation
import MapKit

/// Estados de la vista de gestión de zonas
enum ZonesViewState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

/// ViewModel para la gestión de zonas
@MainActor
final class ZonesManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var zones: [GeoZone] = []
    @Published var markedPoints: [MarkedSalePoint] = []
    @Published var visibleSalePoints: [MarkedSalePoint] = []  // Puntos filtrados por región visible
    @Published var selectedZone: GeoZone?
    @Published var state: ZonesViewState = .idle
    @Published var searchText: String = ""
    @Published var errorMessage: String?
    @Published var isCreating = false
    @Published var isDeleting = false
    @Published var isLoadingMapPoints = false
    
    // MARK: - Private Properties
    
    private let zonesService: ZonesService
    private let adminService: AdminService
    private var lastLoadedRegion: MKCoordinateRegion?
    
    // MARK: - Computed Properties
    
    var filteredZones: [GeoZone] {
        if searchText.isEmpty {
            return zones
        }
        return zones.filter { zone in
            zone.name.localizedCaseInsensitiveContains(searchText) ||
            (zone.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var activeZones: [GeoZone] {
        filteredZones.filter { $0.isActive ?? true }
    }
    
    var inactiveZones: [GeoZone] {
        filteredZones.filter { !($0.isActive ?? true) }
    }
    
    var totalBoundaryPoints: Int {
        zones.reduce(0) { $0 + $1.boundaryPointsCount }
    }
    
    var totalSalePoints: Int {
        zones.reduce(0) { $0 + salePointsCount(for: $1) }
    }
    
    /// Puntos de venta que están dentro de alguna zona (para el mapa)
    var salePointsInAnyZone: [MarkedSalePoint] {
        markedPoints.filter { point in
            let coord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            return zones.contains { zone in
                guard let boundaryPoints = zone.boundaryPoints, boundaryPoints.count >= 3 else { return false }
                let polygon = boundaryPoints.compactMap { $0.coordinate }
                guard polygon.count >= 3 else { return false }
                return isPointInPolygon(point: coord, polygon: polygon)
            }
        }
    }
    
    /// Diccionario con el conteo de puntos de venta por zona
    var salePointsCountByZone: [Int: Int] {
        var counts: [Int: Int] = [:]
        for zone in zones {
            counts[zone.id] = salePointsCount(for: zone)
        }
        return counts
    }
    
    /// Obtener el conteo de puntos de venta para una zona específica
    /// Prioridad: 1) Backend (_count o salePoints array), 2) Cálculo local con ray-casting
    func salePointsCount(for zone: GeoZone) -> Int {
        // Si el backend envía el conteo o el array de salePoints, usarlo
        if zone.salePointsCount > 0 {
            return zone.salePointsCount
        }
        // Fallback: calcular localmente con ray-casting
        return calculateSalePointsInZone(zone)
    }
    
    /// Obtener los puntos de venta que están dentro de una zona específica
    func salePointsForZone(_ zone: GeoZone) -> [MarkedSalePoint] {
        print("📍 salePointsForZone called for zone: \(zone.name)")
        print("📍 Total markedPoints available: \(markedPoints.count)")
        
        guard let boundaryPoints = zone.boundaryPoints, boundaryPoints.count >= 3 else {
            print("⚠️ Zone has no valid boundary points")
            return []
        }
        
        let polygon = boundaryPoints.compactMap { $0.coordinate }
        guard polygon.count >= 3 else {
            print("⚠️ Polygon has less than 3 coordinates")
            return []
        }
        
        let filtered = markedPoints.filter { point in
            let pointCoord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            return isPointInPolygon(point: pointCoord, polygon: polygon)
        }
        
        print("📍 Filtered sale points for \(zone.name): \(filtered.count)")
        return filtered
    }
    
    /// Calcula cuántos puntos marcados están dentro del polígono de una zona (fallback)
    private func calculateSalePointsInZone(_ zone: GeoZone) -> Int {
        guard let boundaryPoints = zone.boundaryPoints, boundaryPoints.count >= 3 else {
            return 0
        }
        
        // Convertir boundary points a coordenadas, filtrando los que no tengan coordenadas válidas
        let polygon = boundaryPoints.compactMap { $0.coordinate }
        guard polygon.count >= 3 else { return 0 }
        
        return markedPoints.filter { point in
            let pointCoord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            return isPointInPolygon(point: pointCoord, polygon: polygon)
        }.count
    }
    
    /// Algoritmo de ray-casting para determinar si un punto está dentro de un polígono
    private func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }
        
        var isInside = false
        var j = polygon.count - 1
        
        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude
            
            let intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
                           (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)
            
            if intersect {
                isInside = !isInside
            }
            
            j = i
        }
        
        return isInside
    }
    
    // MARK: - Initialization
    
    init(zonesService: ZonesService = ZonesService(), adminService: AdminService = AdminService()) {
        self.zonesService = zonesService
        self.adminService = adminService
    }
    
    // MARK: - Public Methods
    
    /// Cargar todas las zonas y puntos marcados
    func loadZones() async {
        state = .loading
        errorMessage = nil
        
        var zonesLoadError: Error?
        var pointsLoadError: Error?
        
        // Cargar zonas primero
        do {
            zones = try await zonesService.listZones()
            print("✅ Zonas cargadas: \(zones.count)")
        } catch {
            zonesLoadError = error
            print("❌ Error cargando zonas: \(error)")
        }
        
        // Cargar puntos marcados (puede fallar independientemente)
        do {
            print("🔄 Iniciando carga de puntos marcados...")
            markedPoints = try await adminService.markedSalePointsMap(zoneId: nil, from: nil, to: nil, markedBy: nil, n: nil, s: nil, e: nil, w: nil)
            print("✅ Puntos marcados cargados: \(markedPoints.count)")
            if markedPoints.isEmpty {
                print("⚠️ La API devolvió un array vacío de puntos marcados")
            } else {
                print("📍 Ejemplo punto: \(markedPoints.first?.name ?? "N/A") en (\(markedPoints.first?.latitude ?? 0), \(markedPoints.first?.longitude ?? 0))")
            }
        } catch {
            pointsLoadError = error
            print("❌ Error cargando puntos marcados: \(error)")
            print("❌ Error detallado: \(error.localizedDescription)")
        }
        
        if zones.isEmpty && markedPoints.isEmpty {
            if let zError = zonesLoadError {
                state = .error("Zonas: \(zError.localizedDescription)")
            } else if let pError = pointsLoadError {
                state = .error("Puntos: \(pError.localizedDescription)")
            } else {
                state = .error("No hay datos disponibles")
            }
        } else {
            state = .loaded
        }
    }
    
    /// Refrescar zonas (pull-to-refresh)
    func refreshZones() async {
        do {
            zones = try await zonesService.listZones()
        } catch {
            print("Error refrescando zonas: \(error)")
        }
        
        do {
            markedPoints = try await adminService.markedSalePointsMap(zoneId: nil, from: nil, to: nil, markedBy: nil, n: nil, s: nil, e: nil, w: nil)
            visibleSalePoints = markedPoints
        } catch {
            print("Error refrescando puntos: \(error)")
        }
        
        state = .loaded
        errorMessage = nil
    }
    
    /// Cargar puntos de venta dentro de la región visible del mapa
    func loadSalePointsInRegion(_ region: MKCoordinateRegion) async {
        // Calcular bounds de la región
        let north = region.center.latitude + region.span.latitudeDelta / 2
        let south = region.center.latitude - region.span.latitudeDelta / 2
        let east = region.center.longitude + region.span.longitudeDelta / 2
        let west = region.center.longitude - region.span.longitudeDelta / 2
        
        // Evitar recargar si la región no cambió significativamente
        if let lastRegion = lastLoadedRegion {
            let latDiff = abs(lastRegion.center.latitude - region.center.latitude)
            let lonDiff = abs(lastRegion.center.longitude - region.center.longitude)
            let spanLatDiff = abs(lastRegion.span.latitudeDelta - region.span.latitudeDelta)
            let spanLonDiff = abs(lastRegion.span.longitudeDelta - region.span.longitudeDelta)
            
            // Si el cambio es menor al 10%, no recargar
            if latDiff < region.span.latitudeDelta * 0.1 &&
               lonDiff < region.span.longitudeDelta * 0.1 &&
               spanLatDiff < region.span.latitudeDelta * 0.1 &&
               spanLonDiff < region.span.longitudeDelta * 0.1 {
                return
            }
        }
        
        lastLoadedRegion = region
        isLoadingMapPoints = true
        
        do {
            let points = try await adminService.markedSalePointsMap(
                zoneId: nil,
                from: nil,
                to: nil,
                markedBy: nil,
                n: north,
                s: south,
                e: east,
                w: west
            )
            visibleSalePoints = points
            print("📍 Cargados \(points.count) puntos para región visible")
        } catch {
            print("❌ Error cargando puntos por región: \(error)")
            // En caso de error, usar los puntos ya cargados filtrados localmente
            visibleSalePoints = markedPoints.filter { point in
                point.latitude >= south && point.latitude <= north &&
                point.longitude >= west && point.longitude <= east
            }
        }
        
        isLoadingMapPoints = false
    }
    
    /// Obtener detalle de una zona
    func loadZoneDetail(id: Int) async -> GeoZone? {
        do {
            let zone = try await zonesService.getZone(id: id)
            // Actualizar en la lista local
            if let index = zones.firstIndex(where: { $0.id == id }) {
                zones[index] = zone
            }
            return zone
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    /// Crear una nueva zona
    func createZone(name: String, isDangerous: Bool, boundaryPoints: [CLLocationCoordinate2D]?) async -> GeoZone? {
        isCreating = true
        defer { isCreating = false }
        
        do {
            let newZone = try await zonesService.createZone(
                name: name,
                isDangerous: isDangerous,
                boundaryPoints: boundaryPoints
            )
            zones.insert(newZone, at: 0)
            return newZone
        } catch {
            errorMessage = "Error al crear zona: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Actualizar una zona existente
    func updateZone(id: Int, name: String?, isDangerous: Bool?, isActive: Bool?) async -> Bool {
        do {
            let updatedZone = try await zonesService.updateZone(
                id: id,
                name: name,
                isDangerous: isDangerous,
                isActive: isActive
            )
            
            // Actualizar en la lista local
            if let index = zones.firstIndex(where: { $0.id == id }) {
                zones[index] = updatedZone
            }
            
            // Actualizar zona seleccionada si es la misma
            if selectedZone?.id == id {
                selectedZone = updatedZone
            }
            
            return true
        } catch {
            errorMessage = "Error al actualizar zona: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Eliminar una zona
    func deleteZone(_ zone: GeoZone) async -> Bool {
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            try await zonesService.deleteZone(id: zone.id)
            zones.removeAll { $0.id == zone.id }
            
            if selectedZone?.id == zone.id {
                selectedZone = nil
            }
            
            return true
        } catch {
            errorMessage = "Error al eliminar zona: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Actualizar puntos del perímetro de una zona
    func updateBoundaryPoints(zoneId: Int, points: [CLLocationCoordinate2D]) async -> Bool {
        do {
            let updatedZone = try await zonesService.setBoundaryPoints(zoneId: zoneId, points: points)
            
            // Actualizar en la lista local
            if let index = zones.firstIndex(where: { $0.id == zoneId }) {
                zones[index] = updatedZone
            }
            
            if selectedZone?.id == zoneId {
                selectedZone = updatedZone
            }
            
            return true
        } catch {
            errorMessage = "Error al actualizar perímetro: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Zone Assignments
    
    /// Asignar usuario a zona
    func assignUser(userId: Int, toZone zoneId: Int) async -> Bool {
        do {
            _ = try await zonesService.assignUserToZone(zoneId: zoneId, userId: userId)
            // Recargar la zona para obtener las asignaciones actualizadas
            _ = await loadZoneDetail(id: zoneId)
            return true
        } catch {
            errorMessage = "Error al asignar usuario: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Eliminar asignación
    func removeAssignment(assignmentId: Int, fromZone zoneId: Int) async -> Bool {
        do {
            _ = try await zonesService.removeAssignment(assignmentId: assignmentId)
            // Recargar la zona para obtener las asignaciones actualizadas
            _ = await loadZoneDetail(id: zoneId)
            return true
        } catch {
            errorMessage = "Error al eliminar asignación: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Geographic Search
    
    /// Buscar zonas por ubicación actual
    func searchZonesNearby(location: CLLocationCoordinate2D, radiusMeters: Double = 5000) async {
        state = .loading
        
        do {
            zones = try await zonesService.searchZonesByRadius(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusMeters: radiusMeters
            )
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    /// Buscar zonas en región visible del mapa
    func searchZonesInRegion(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double) async {
        do {
            let zonesInRegion = try await zonesService.searchZonesByBoundingBox(
                minLat: minLat,
                maxLat: maxLat,
                minLng: minLng,
                maxLng: maxLng
            )
            
            // Merge con zonas existentes sin duplicados
            let existingIds = Set(zones.map { $0.id })
            let newZones = zonesInRegion.filter { !existingIds.contains($0.id) }
            zones.append(contentsOf: newZones)
        } catch {
            // Silently fail for region search - no interrumpir UX
            print("Error searching zones in region: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    func clearError() {
        errorMessage = nil
    }
    
    func selectZone(_ zone: GeoZone?) {
        selectedZone = zone
    }
    
    /// Cargar usuarios disponibles para asignación
    func loadUsersForAssignment() async -> [UserBasic] {
        do {
            // Intentar cargar usuarios desde el endpoint de admin
            let endpoint = Endpoint(path: "/users", method: .get)
            let client = APIClient.shared
            let users: [UserBasic] = try await client.request(endpoint, responseType: [UserBasic].self)
            return users
        } catch {
            print("Error cargando usuarios: \(error)")
            return []
        }
    }
    
    /// Asignar zona a un usuario
    func assignZoneToUser(zoneId: Int, userId: Int) async {
        do {
            try await adminService.assignZone(zoneId: zoneId, userId: userId)
            // Recargar zonas para actualizar conteos
            await refreshZones()
        } catch {
            errorMessage = "Error al asignar zona: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sale Points Management
    
    /// Actualizar un punto de venta marcado (usando endpoint admin)
    func updateSalePoint(id: Int, request: UpdateSalePointRequest) async {
        do {
            // Usar endpoint admin para puntos marcados que acepta todos los campos
            let endpoint = Endpoint(path: "/admin/marked-sale-points/\(id)", method: .patch, body: request)
            
            // Debug: mostrar qué campos se están enviando
            if let data = try? JSONEncoder().encode(request),
               let jsonString = String(data: data, encoding: .utf8) {
                print("📤 Enviando PATCH a /admin/marked-sale-points/\(id)")
                print("📤 Body: \(jsonString)")
            }
            
            let updated: MarkedSalePoint = try await APIClient.shared.request(endpoint, responseType: MarkedSalePoint.self)
            print("✅ Punto de venta actualizado correctamente: \(updated.name)")
            
            // Actualizar en la lista local
            if let index = markedPoints.firstIndex(where: { $0.id == id }) {
                markedPoints[index] = updated
            }
        } catch let error as APIError {
            errorMessage = "Error al actualizar punto de venta: \(error.localizedDescription)"
            print("❌ Error API al actualizar sale point: \(error)")
            
            // Si el endpoint admin no existe, intentar con el endpoint normal
            if case .httpStatus(let code) = error, code == 404 {
                print("⚠️ Endpoint admin no encontrado, intentando con /sale-points/\(id)")
                await updateSalePointFallback(id: id, request: request)
            }
        } catch {
            errorMessage = "Error al actualizar punto de venta: \(error.localizedDescription)"
            print("❌ Error general al actualizar sale point: \(error)")
        }
    }
    
    /// Fallback: actualizar usando endpoint normal (solo campos básicos)
    private func updateSalePointFallback(id: Int, request: UpdateSalePointRequest) async {
        do {
            let endpoint = Endpoint(path: "/sale-points/\(id)", method: .patch, body: request)
            let updated: MarkedSalePoint = try await APIClient.shared.request(endpoint, responseType: MarkedSalePoint.self)
            print("✅ Punto de venta actualizado (fallback): \(updated.name)")
            
            if let index = markedPoints.firstIndex(where: { $0.id == id }) {
                markedPoints[index] = updated
            }
        } catch {
            print("❌ Error en fallback: \(error)")
        }
    }
    
    /// Cargar puntos de venta de una zona específica
    func loadSalePointsForZone(_ zoneId: Int) async -> [MarkedSalePoint] {
        do {
            let queryItems = [URLQueryItem(name: "zoneId", value: String(zoneId))]
            let endpoint = Endpoint(path: "/sale-points", method: .get, queryItems: queryItems)
            return try await APIClient.shared.request(endpoint, responseType: [MarkedSalePoint].self)
        } catch {
            print("Error loading sale points for zone \(zoneId): \(error)")
            return []
        }
    }
}
