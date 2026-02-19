import SwiftUI
import MapKit

struct GPSRecordingView: View {
    @StateObject private var viewModel: GPSRecordingViewModel
    @ObservedObject private var locationService = LocationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @State private var hasInitializedLocation = false
    @State private var showStopConfirmation = false
    @State private var selectedSalePoint: SalePoint?
    @State private var showSalePointSheet = false
    @State private var isMapExpanded = false
    @State private var isSelectingLocation = false
    @State private var customPinLocation: CLLocationCoordinate2D?
    @State private var showCustomLocationConfirmation = false
    
    init(track: Track) {
        _viewModel = StateObject(wrappedValue: GPSRecordingViewModel(track: track))
        
        // Inicializar región con ubicación actual si está disponible, sino usar ubicación por defecto
        if let currentLocation = LocationService.shared.currentLocation {
            _region = State(initialValue: MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            ))
        } else {
            // Ubicación por defecto (se actualizará cuando llegue la ubicación real)
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            ))
            // Solicitar ubicación inmediatamente
            LocationService.shared.requestSingleLocation()
        }
    }
    
    var body: some View {
        ZStack {
            // Mapa de fondo (ocupa toda la pantalla)
            recordingMapView
                .ignoresSafeArea()
            
            // Fondo para TabBar con material translúcido
            VStack {
                Spacer()
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 90)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Overlay para selección de ubicación personalizada
            if isSelectingLocation {
                locationSelectionOverlay
            }
            
            // Indicador de grabación (arriba centro)
            VStack {
                if !isSelectingLocation {
                    recordingIndicator
                }
                Spacer()
            }
            
            // Botones flotantes (abajo izquierda)
            if !isSelectingLocation {
                VStack {
                    Spacer()
                    floatingControlButtons
                }
            }
        }
        .navigationTitle(viewModel.track.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.state == .recording || viewModel.state == .paused || isSelectingLocation)
        .toolbar {
            // Indicador de sync pendiente
            if viewModel.pendingSyncCount > 0 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    syncIndicator
                }
            }
        }
        .overlay {
            // Modal de finalizar/eliminar grabación
            if showStopConfirmation {
                stopRecordingModal
            }
        }
        .sheet(isPresented: $showSalePointSheet) {
            if let point = selectedSalePoint {
                SalePointDetailSheet(
                    salePoint: point,
                    track: viewModel.track,
                    onDelete: {
                        viewModel.salePoints.removeAll { $0.id == point.id }
                        showSalePointSheet = false
                    },
                    onTransfer: { _ in
                        viewModel.salePoints.removeAll { $0.id == point.id }
                        showSalePointSheet = false
                    }
                )
                .presentationDetents([.large, .medium], selection: .constant(.large))
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: viewModel.currentLocation) { _, newLocation in
            Task { @MainActor in
                if let location = newLocation {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        region.center = location.coordinate
                    }
                }
            }
        }
        .onChange(of: locationService.currentLocation) { _, newLocation in
            Task { @MainActor in
                // Centrar mapa cuando llegue la primera ubicación
                if !hasInitializedLocation, let location = newLocation {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        region.center = location.coordinate
                    }
                    hasInitializedLocation = true
                }
            }
        }
        .onAppear {
            // Solicitar permisos de notificaciones
            Task {
                _ = await RecordingNotificationService.shared.requestAuthorization()
            }
            
            // Centrar mapa en ubicación actual del usuario (en Task para evitar warning)
            Task { @MainActor in
                initializeMapLocation()
            }
        }
    }
    
    /// Inicializa el mapa en la ubicación actual del usuario
    private func initializeMapLocation() {
        guard !hasInitializedLocation else { return }
        
        // Intentar obtener ubicación actual inmediatamente
        if let currentLocation = locationService.currentLocation {
            withAnimation(.easeInOut(duration: 0.5)) {
                region.center = currentLocation.coordinate
            }
            hasInitializedLocation = true
            return
        }
        
        // Iniciar proceso de obtención de ubicación en background
        Task { @MainActor in
            await waitForLocationAndCenter()
        }
    }
    
    /// Espera hasta obtener una ubicación válida y centra el mapa
    private func waitForLocationAndCenter() async {
        // Si ya tenemos ubicación, centrar inmediatamente
        if let location = locationService.currentLocation {
            centerMap(on: location.coordinate)
            return
        }
        
        // Solicitar permisos si es necesario
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestPermission()
            
            // Esperar hasta que los permisos cambien (máximo 10 segundos)
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
                if locationService.authorizationStatus != .notDetermined {
                    break
                }
            }
        }
        
        // Verificar si tenemos permisos
        guard locationService.authorizationStatus == .authorizedWhenInUse ||
              locationService.authorizationStatus == .authorizedAlways else {
            print("⚠️ No hay permisos de ubicación")
            return
        }
        
        // Solicitar ubicación y esperar (máximo 5 segundos con reintentos)
        for attempt in 1...5 {
            locationService.requestSingleLocation()
            
            // Esperar 1 segundo por cada intento
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            if let location = locationService.currentLocation {
                print("✅ Ubicación obtenida en intento \(attempt)")
                centerMap(on: location.coordinate)
                return
            }
        }
        
        print("⚠️ No se pudo obtener ubicación después de 5 intentos")
    }
    
    /// Centra el mapa en las coordenadas especificadas
    private func centerMap(on coordinate: CLLocationCoordinate2D) {
        guard !hasInitializedLocation else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = coordinate
        }
        hasInitializedLocation = true
    }
    
    // MARK: - Recording Map View
    
    private var recordingMapView: some View {
        RecordingMapRepresentable(
            region: $region,
            previousPoints: viewModel.previousPoints,
            currentPoints: viewModel.currentSessionPoints,
            salePoints: viewModel.salePoints,
            isRecording: viewModel.state == .recording,
            isSelectingLocation: isSelectingLocation,
            selectedCoordinate: $customPinLocation,
            onSalePointTap: { point in
                selectedSalePoint = point
                showSalePointSheet = true
            },
            onMapTap: { coordinate in
                // Solo procesar si estamos en modo selección
                if isSelectingLocation {
                    customPinLocation = coordinate
                }
            }
        )
    }
    
    // MARK: - Floating Control Buttons
    
    private var floatingControlButtons: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                // Solo mostrar botones de marcado cuando está grabando o pausado
                if viewModel.state == .recording || viewModel.state == .paused {
                    // Botón CHICO: selección manual en mapa (arriba) - GRIS
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(CaleiAnimations.spring) {
                            isSelectingLocation = true
                        }
                    } label: {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(CaleiColors.gray600)
                            .clipShape(Circle())
                    }
                    
                    // Botón GRANDE: ubicación actual (abajo) - ACCENT
                    Button {
                        guard viewModel.currentLocation != nil else { return }
                        Task {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            await viewModel.markCurrentLocationAsPoint()
                        }
                    } label: {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(CaleiColors.accent)
                            .clipShape(Circle())
                    }
                    .opacity(viewModel.currentLocation == nil ? 0.5 : 1)
                    .disabled(viewModel.currentLocation == nil)
                }
                
                // Estado idle: Botón de iniciar grabación
                if viewModel.state == .idle {
                    Button {
                        withAnimation(CaleiAnimations.spring) {
                            viewModel.startRecording()
                        }
                    } label: {
                        Image(systemName: "record.circle")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(CaleiColors.error)
                            .clipShape(Circle())
                    }
                }
                
                // Estado saving
                if viewModel.state == .saving {
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(.white)
                        .frame(width: 72, height: 72)
                        .background(CaleiColors.accent.opacity(0.9))
                        .clipShape(Circle())
                }
                
                // Estado error
                if case .error = viewModel.state {
                    Button {
                        // Reintentar
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(CaleiColors.error)
                            .clipShape(Circle())
                    }
                }
            }
            .position(
                x: geometry.size.width - 52,
                y: geometry.size.height - 100
            )
        }
    }
    
    private func floatingButton(
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
        }
    }
    
    // MARK: - Mark Point Button (Current Location)
    
    /// Botón para marcar punto en la ubicación GPS actual
    private var currentLocationMarkButton: some View {
        Button {
            guard viewModel.currentLocation != nil else { return }
            Task {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                await viewModel.markCurrentLocationAsPoint()
            }
        } label: {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(CaleiColors.accent)
                .clipShape(Circle())
                .shadow(color: CaleiColors.accent.opacity(0.4), radius: 8, y: 4)
        }
        .opacity(viewModel.currentLocation == nil ? 0.5 : 1)
        .disabled(viewModel.currentLocation == nil)
    }
    
    /// Botón para activar modo de selección manual en el mapa
    private var manualLocationMarkButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(CaleiAnimations.spring) {
                isSelectingLocation = true
            }
        } label: {
            Image(systemName: "hand.tap")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(CaleiColors.info)
                .clipShape(Circle())
                .shadow(color: CaleiColors.info.opacity(0.4), radius: 8, y: 4)
        }
    }
    
    // MARK: - Location Selection Overlay (Tap to Select)
    
    private var locationSelectionOverlay: some View {
        ZStack {
            // Instrucciones arriba
            VStack {
                HStack {
                    // Botón cancelar
                    Button {
                        withAnimation(CaleiAnimations.spring) {
                            isSelectingLocation = false
                            customPinLocation = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(CaleiColors.gray600)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Instrucción
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 12))
                        Text("Toca el mapa")
                            .font(CaleiTypography.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(CaleiColors.gray600)
                    )
                    
                    Spacer()
                    
                    // Spacer para balance
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                // Mostrar coordenadas y botón confirmar si hay pin seleccionado
                if let coordinate = customPinLocation {
                    VStack(spacing: 12) {
                        // Coordenadas
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(CaleiColors.accent)
                            Text("\(coordinate.latitude, specifier: "%.6f"), \(coordinate.longitude, specifier: "%.6f")")
                                .font(CaleiTypography.caption.monospaced())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        
                        // Botón de confirmación
                        Button {
                            confirmCustomLocation()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Confirmar")
                                    .font(CaleiTypography.button)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(CaleiColors.accent)
                            .cornerRadius(24)
                        }
                    }
                    .padding(.bottom, 110)
                }
            }
        }
    }
    
    private func confirmCustomLocation() {
        // Usar la ubicación donde el usuario tocó el mapa
        guard let coordinate = customPinLocation else { return }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Marcar el punto en la ubicación seleccionada
        Task {
            await viewModel.markLocationAsPoint(coordinate: coordinate)
        }
        
        // Cerrar modo selección con animación
        withAnimation(CaleiAnimations.spring) {
            isSelectingLocation = false
            customPinLocation = nil
        }
    }
    
    // MARK: - Recording Indicator
    
    private var recordingIndicator: some View {
        HStack {
            // IZQUIERDA: Botón de detener
            if viewModel.state == .recording || viewModel.state == .paused {
                Button {
                    showStopConfirmation = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(CaleiColors.gray600)
                        .clipShape(Circle())
                }
            } else {
                Color.clear
                    .frame(width: 36, height: 36)
            }
            
            Spacer()
            
            // CENTRO: Control de pausar/reanudar
            Group {
                if viewModel.state == .recording {
                    Button {
                        viewModel.pauseRecording()
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                            
                            Text(viewModel.formattedDuration)
                                .font(CaleiTypography.caption)
                                .foregroundColor(.white)
                            
                            Image(systemName: "pause.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(CaleiColors.error)
                        )
                    }
                } else if viewModel.state == .paused {
                    Button {
                        viewModel.resumeRecording()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .medium))
                            
                            Text(viewModel.formattedDuration)
                                .font(CaleiTypography.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(CaleiColors.warning)
                        )
                    }
                }
            }
            
            Spacer()
            
            // Espaciador derecho para balance
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(CaleiAnimations.spring, value: viewModel.state)
    }
    
    // MARK: - Sync Indicator
    
    private var syncIndicator: some View {
        HStack(spacing: 4) {
            if !viewModel.isOnline {
                Image(systemName: "wifi.slash")
                    .font(.caption)
            } else {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.caption)
            }
            Text("\(viewModel.pendingSyncCount)")
                .font(CaleiTypography.caption)
        }
        .foregroundColor(viewModel.isOnline ? CaleiColors.accent : CaleiColors.warning)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(CaleiColors.accentSoft)
        .cornerRadius(20)
    }
    
    // MARK: - Stop Recording Modal
    
    private var stopRecordingModal: some View {
        ZStack {
            // Fondo oscuro
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(CaleiAnimations.spring) {
                        showStopConfirmation = false
                    }
                }
            
            // Modal centrado
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 32))
                        .foregroundColor(CaleiColors.accent)
                    
                    Text("¿Finalizar grabación?")
                        .font(CaleiTypography.h3)
                        .foregroundColor(CaleiColors.dark)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Info
                VStack(spacing: 4) {
                    Text("Se guardarán:")
                        .font(CaleiTypography.bodySmall)
                        .foregroundColor(CaleiColors.gray500)
                    
                    HStack(spacing: 16) {
                        VStack {
                            Text("\(viewModel.recordedPoints.count)")
                                .font(CaleiTypography.h2)
                                .foregroundColor(CaleiColors.accent)
                            Text("puntos GPS")
                                .font(CaleiTypography.caption)
                                .foregroundColor(CaleiColors.gray500)
                        }
                        
                        Rectangle()
                            .fill(CaleiColors.gray200)
                            .frame(width: 1, height: 40)
                        
                        VStack {
                            Text("\(viewModel.pointsMarkedCount)")
                                .font(CaleiTypography.h2)
                                .foregroundColor(CaleiColors.accent)
                            Text("puntos de venta")
                                .font(CaleiTypography.caption)
                                .foregroundColor(CaleiColors.gray500)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                Divider()
                
                // Botones
                VStack(spacing: 12) {
                    // Finalizar y guardar
                    Button {
                        Task {
                            await viewModel.stopRecording()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Finalizar y guardar")
                        }
                        .font(CaleiTypography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CaleiColors.accent)
                        .cornerRadius(12)
                    }
                    
                    // Continuar grabando
                    Button {
                        withAnimation(CaleiAnimations.spring) {
                            showStopConfirmation = false
                        }
                    } label: {
                        Text("Continuar grabando")
                            .font(CaleiTypography.button)
                            .foregroundColor(CaleiColors.gray600)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .padding(20)
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }
}

// MARK: - Recording Map Representable

/// Polyline personalizada para identificar tipo
class TypedPolyline: MKPolyline {
    var polylineType: PolylineType = .current
    
    enum PolylineType {
        case previous  // Grabaciones previas - morado
        case current   // Grabación actual - azul
    }
}

struct RecordingMapRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let previousPoints: [CLLocationCoordinate2D]  // Coordenadas de grabaciones previas
    let currentPoints: [CLLocationCoordinate2D]   // Coordenadas de la grabación actual
    let salePoints: [SalePoint]
    let isRecording: Bool
    let isSelectingLocation: Bool
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    let onSalePointTap: (SalePoint) -> Void
    let onMapTap: ((CLLocationCoordinate2D) -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Agregar tap gesture recognizer para selección de puntos
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        // Permitir que el tap funcione junto con otros gestures del mapa
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Actualizar el estado de selección en el coordinator
        context.coordinator.isSelectingLocation = isSelectingLocation
        
        // Actualizar polylines
        mapView.removeOverlays(mapView.overlays)
        
        // Agregar polyline de grabaciones PREVIAS (morado)
        if !previousPoints.isEmpty {
            var coords = previousPoints
            let previousPolyline = TypedPolyline(coordinates: &coords, count: previousPoints.count)
            previousPolyline.polylineType = .previous
            mapView.addOverlay(previousPolyline, level: .aboveRoads)
        }
        
        // Agregar polyline de grabación ACTUAL (azul) - encima de la previa
        if !currentPoints.isEmpty {
            var coords = currentPoints
            let currentPolyline = TypedPolyline(coordinates: &coords, count: currentPoints.count)
            currentPolyline.polylineType = .current
            mapView.addOverlay(currentPolyline, level: .aboveRoads)
        }
        
        // Actualizar marcadores de puntos de venta
        let existingAnnotations = mapView.annotations.compactMap { $0 as? SalePointAnnotation }
        let existingIds = Set(existingAnnotations.map { $0.salePoint.id })
        let newSalePointIds = Set(salePoints.map { $0.id })
        
        // Remover los que ya no existen
        for annotation in existingAnnotations {
            if !newSalePointIds.contains(annotation.salePoint.id) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        // Agregar los nuevos sale points
        for point in salePoints {
            if !existingIds.contains(point.id), let coord = point.coordinate {
                let annotation = SalePointAnnotation(salePoint: point)
                annotation.coordinate = coord
                annotation.title = point.name
                mapView.addAnnotation(annotation)
            }
        }
        
        // Manejar el pin de selección manual
        let existingSelectionPins = mapView.annotations.compactMap { $0 as? SelectionPinAnnotation }
        
        if isSelectingLocation, let coordinate = selectedCoordinate {
            // Modo selección activo con coordenada
            if let existingPin = existingSelectionPins.first {
                // Actualizar posición del pin existente
                UIView.animate(withDuration: 0.2) {
                    existingPin.coordinate = coordinate
                }
            } else {
                // Agregar nuevo pin
                let pin = SelectionPinAnnotation()
                pin.coordinate = coordinate
                pin.title = "Punto seleccionado"
                mapView.addAnnotation(pin)
            }
        } else {
            // Remover todos los pins de selección
            for pin in existingSelectionPins {
                mapView.removeAnnotation(pin)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: RecordingMapRepresentable
        var isSelectingLocation = false
        
        init(_ parent: RecordingMapRepresentable) {
            self.parent = parent
        }
        
        // Permitir que el tap gesture funcione simultáneamente con otros gestures
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard isSelectingLocation else { return }
            guard gesture.state == .ended else { return }
            
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Verificar que la coordenada sea válida
            guard CLLocationCoordinate2DIsValid(coordinate) else { return }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Actualizar la coordenada seleccionada
            DispatchQueue.main.async {
                self.parent.selectedCoordinate = coordinate
                self.parent.onMapTap?(coordinate)
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let typedPolyline = overlay as? TypedPolyline {
                let renderer = MKPolylineRenderer(polyline: typedPolyline)
                renderer.lineCap = .round
                renderer.lineJoin = .round
                
                switch typedPolyline.polylineType {
                case .previous:
                    // Polyline de grabaciones previas - MORADO
                    renderer.strokeColor = UIColor(red: 0.541, green: 0.439, blue: 0.855, alpha: 1.0)
                    renderer.lineWidth = 4
                case .current:
                    // Polyline de grabación actual - AZUL
                    renderer.strokeColor = UIColor(red: 0.208, green: 0.435, blue: 0.976, alpha: 1.0)
                    renderer.lineWidth = 5
                }
                
                return renderer
            } else if let polyline = overlay as? MKPolyline {
                // Fallback para MKPolyline normal
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(CaleiColors.accent)
                renderer.lineWidth = 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Pin de selección manual
            if let selectionPin = annotation as? SelectionPinAnnotation {
                let identifier = "SelectionPin"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: selectionPin, reuseIdentifier: identifier)
                    view?.canShowCallout = false
                } else {
                    view?.annotation = selectionPin
                }
                
                view?.markerTintColor = UIColor(CaleiColors.info)
                view?.glyphImage = UIImage(systemName: "mappin")
                view?.animatesWhenAdded = true
                
                return view
            }
            
            // Sale point annotation
            guard let salePointAnnotation = annotation as? SalePointAnnotation else {
                return nil
            }
            
            let identifier = "SalePointMarker"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: salePointAnnotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            } else {
                view?.annotation = salePointAnnotation
            }
            
            view?.markerTintColor = UIColor(CaleiColors.success)
            view?.glyphImage = UIImage(systemName: "mappin")
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            if let salePointAnnotation = annotation as? SalePointAnnotation {
                parent.onSalePointTap(salePointAnnotation.salePoint)
                mapView.deselectAnnotation(annotation, animated: true)
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Sincronizar la región del binding con la del mapa
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

// MARK: - Sale Point Annotation

class SalePointAnnotation: MKPointAnnotation {
    let salePoint: SalePoint
    
    init(salePoint: SalePoint) {
        self.salePoint = salePoint
        super.init()
    }
}

// MARK: - Selection Pin Annotation

class SelectionPinAnnotation: MKPointAnnotation {
    // Clase separada para identificar pins de selección manual
}

// MARK: - Preview

#Preview {
    NavigationView {
        GPSRecordingView(track: Track(
            id: 1,
            name: "Recorrido Test",
            description: nil,
            userId: 1,
            completed: false,
            createdAt: nil,
            updatedAt: nil,
            subTracks: nil,
            salePoints: nil,
            salePointsCount: nil,
            _count: nil
        ))
    }
}
