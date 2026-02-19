import SwiftUI
import MapKit

struct TrackDetailView: View {
    @StateObject private var viewModel: TrackDetailViewModel
    @ObservedObject private var locationService = LocationService.shared
    @State private var region: MKCoordinateRegion
    @State private var selectedSalePoint: SalePoint?
    @State private var mapType: MKMapType = .standard
    
    init(trackId: Int) {
        _viewModel = StateObject(wrappedValue: TrackDetailViewModel(trackId: trackId))
        
        // Inicializar región con ubicación actual si está disponible
        if let currentLocation = LocationService.shared.currentLocation {
            _region = State(initialValue: MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        } else {
            // Ubicación por defecto (se actualizará cuando llegue la ubicación o datos del track)
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
            // Solicitar ubicación
            LocationService.shared.requestSingleLocation()
        }
    }
    
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                loadingView
                
            case .error(let message):
                errorView(message: message)
                
            case .idle, .loaded:
                if let track = viewModel.track {
                    trackContent(track)
                }
            }
        }
        .navigationTitle(viewModel.track?.name ?? "Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let track = viewModel.track {
                    NavigationLink(value: TracksNavigationDestination.gpsRecording(track: track)) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(CaleiColors.error)
                                .frame(width: 8, height: 8)
                            Text("Grabar")
                                .font(CaleiTypography.buttonSmall)
                        }
                        .foregroundColor(CaleiColors.error)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(CaleiColors.error.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
        }
        .sheet(item: $selectedSalePoint) { point in
            if let track = viewModel.track {
                SalePointDetailSheet(
                    salePoint: point,
                    track: track,
                    onDelete: {
                        Task {
                            await viewModel.deleteSalePoint(point)
                            selectedSalePoint = nil
                        }
                    },
                    onTransfer: { newTrackId in
                        Task {
                            await viewModel.transferSalePoint(point, toTrackId: newTrackId)
                            selectedSalePoint = nil
                        }
                    }
                )
                .presentationDetents([.large, .medium], selection: .constant(.large))
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await viewModel.loadTrack()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: CaleiSpacing.space4) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(CaleiColors.accent)
            
            Text("Cargando recorrido...")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: CaleiSpacing.space6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(CaleiColors.warning)
            
            Text(message)
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray500)
                .multilineTextAlignment(.center)
            
            Button {
                Task { await viewModel.loadTrack() }
            } label: {
                Text("Reintentar")
                    .caleiSecondaryButton()
            }
        }
        .padding()
    }
    
    // MARK: - Track Content
    
    private func trackContent(_ track: Track) -> some View {
        ScrollView {
            VStack(spacing: CaleiSpacing.space4) {
                // Mapa con polyline
                mapSection
                
                // Estadísticas
                statsSection
                
                // Descripción
                if let description = track.description, !description.isEmpty {
                    descriptionSection(description)
                }
                
                // Puntos de venta
                salePointsSection
            }
            .padding()
        }
        .background(CaleiColors.gray50)
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: CaleiSpacing.space3) {
            HStack {
                Text("Ruta")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                
                Spacer()
                
                // Toggle de tipo de mapa
                Menu {
                    Button {
                        mapType = .standard
                    } label: {
                        Label("Estándar", systemImage: mapType == .standard ? "checkmark" : "")
                    }
                    
                    Button {
                        mapType = .satellite
                    } label: {
                        Label("Satélite", systemImage: mapType == .satellite ? "checkmark" : "")
                    }
                    
                    Button {
                        mapType = .hybrid
                    } label: {
                        Label("Híbrido", systemImage: mapType == .hybrid ? "checkmark" : "")
                    }
                } label: {
                    Image(systemName: "map")
                        .font(.subheadline)
                        .foregroundColor(CaleiColors.accent)
                        .padding(8)
                        .background(CaleiColors.accentSoft)
                        .clipShape(Circle())
                }
            }
            
            // Mapa con polyline y marcadores
            TrackMapView(
                region: $region,
                coordinates: viewModel.coordinates,
                salePoints: viewModel.salePoints,
                mapType: mapType,
                onSalePointTap: { point in
                    selectedSalePoint = point
                }
            )
            .frame(height: 250)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CaleiColors.gray200, lineWidth: 1)
            )
            .onAppear {
                Task { @MainActor in
                    centerMapOnContent()
                }
            }
            .onChange(of: locationService.currentLocation) { _, newLocation in
                // Si no hay datos del track y llegó una nueva ubicación, centrar en ella
                if viewModel.coordinates.isEmpty && viewModel.salePoints.isEmpty,
                   let location = newLocation {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        region.center = location.coordinate
                    }
                }
            }
        }
        .caleiCard()
    }
    
    private func centerMapOnContent() {
        // Recolectar todas las coordenadas (del track y de puntos de venta)
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        // Agregar coordenadas del track
        for coord in viewModel.coordinates {
            allCoordinates.append(CLLocationCoordinate2D(
                latitude: coord.latitude,
                longitude: coord.longitude
            ))
        }
        
        // Agregar coordenadas de puntos de venta
        for salePoint in viewModel.salePoints {
            if let coord = salePoint.coordinate {
                allCoordinates.append(coord)
            }
        }
        
        // Si hay coordenadas, calcular el bounding box y ajustar zoom
        if !allCoordinates.isEmpty {
            fitMapToCoordinates(allCoordinates)
        // Si no hay datos, usar ubicación del usuario
        } else if let currentLocation = locationService.currentLocation {
            region.center = currentLocation.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
        // Si no hay nada, mantiene la ubicación por defecto
    }
    
    /// Ajusta la región del mapa para que todas las coordenadas sean visibles
    private func fitMapToCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        
        // Si solo hay un punto, centrar con zoom fijo
        if coordinates.count == 1 {
            region.center = coordinates[0]
            region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            return
        }
        
        // Calcular bounding box
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        // Calcular centro
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Calcular span con padding (20% extra para que los puntos no queden en el borde)
        let latDelta = (maxLat - minLat) * 1.4
        let lonDelta = (maxLon - minLon) * 1.4
        
        // Asegurar un span mínimo para que no quede demasiado cerca
        let finalLatDelta = max(latDelta, 0.002)
        let finalLonDelta = max(lonDelta, 0.002)
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLonDelta)
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: CaleiSpacing.space3) {
            HStack {
                Text("Estadísticas")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                Spacer()
            }
            
            HStack(spacing: 0) {
                statItem(
                    value: viewModel.formattedDistance,
                    label: "Distancia",
                    icon: "arrow.triangle.swap",
                    color: CaleiColors.accent
                )
                
                Divider()
                    .frame(height: 50)
                
                statItem(
                    value: "\(viewModel.pointsCount)",
                    label: "Puntos",
                    icon: "mappin.circle.fill",
                    color: CaleiColors.success
                )
                
                Divider()
                    .frame(height: 50)
                
                statItem(
                    value: "\(viewModel.segmentsCount)",
                    label: "Segmentos",
                    icon: "location.fill",
                    color: CaleiColors.info
                )
            }
        }
        .caleiCard()
    }
    
    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(CaleiTypography.h3)
                .foregroundColor(CaleiColors.dark)
            
            Text(label)
                .font(CaleiTypography.caption)
                .foregroundColor(CaleiColors.gray500)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: CaleiSpacing.space3) {
            Text("Descripción")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.dark)
            
            Text(description)
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.gray600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .caleiCard()
    }
    
    // MARK: - Sale Points Section
    
    private var salePointsSection: some View {
        VStack(alignment: .leading, spacing: CaleiSpacing.space3) {
            HStack {
                Text("Puntos de venta")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                
                Text("(\(viewModel.pointsCount))")
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.gray500)
                
                Spacer()
            }
            
            if viewModel.salePoints.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: CaleiSpacing.space3) {
                        Image(systemName: "mappin.slash")
                            .font(.title)
                            .foregroundColor(CaleiColors.gray400)
                        
                        Text("Sin puntos de venta")
                            .font(CaleiTypography.bodySmall)
                            .foregroundColor(CaleiColors.gray500)
                    }
                    .padding(.vertical, CaleiSpacing.space6)
                    Spacer()
                }
            } else {
                ForEach(viewModel.salePoints) { point in
                    Button {
                        selectedSalePoint = point
                    } label: {
                        salePointRow(point)
                    }
                    .buttonStyle(CardButtonStyle())
                }
            }
        }
        .caleiCard()
    }
    
    private func salePointRow(_ point: SalePoint) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(CaleiColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(point.name)
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(CaleiColors.dark)
                
                if let coord = point.coordinate {
                    Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(CaleiColors.gray400)
        }
        .padding(12)
        .background(CaleiColors.gray50)
        .cornerRadius(12)
    }
}

// MARK: - Track Map View (con polyline)

struct TrackMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let coordinates: [(latitude: Double, longitude: Double)]
    let salePoints: [SalePoint]
    let mapType: MKMapType
    let onSalePointTap: (SalePoint) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        
        // Remover overlays y anotaciones anteriores
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Recolectar todas las coordenadas para calcular el bounding box
        var allCoords: [CLLocationCoordinate2D] = []
        
        // Agregar polyline y sus coordenadas
        if !coordinates.isEmpty {
            let coords = coordinates.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView.addOverlay(polyline)
            allCoords.append(contentsOf: coords)
        }
        
        // Agregar marcadores de puntos de venta y sus coordenadas
        for point in salePoints {
            if let coord = point.coordinate {
                let annotation = TrackSalePointAnnotation(salePoint: point)
                annotation.coordinate = coord
                annotation.title = point.name
                mapView.addAnnotation(annotation)
                allCoords.append(coord)
            }
        }
        
        // Ajustar región para mostrar todos los puntos (ruta + puntos de venta)
        if !allCoords.isEmpty {
            fitMapToAllCoordinates(mapView: mapView, coordinates: allCoords)
        }
    }
    
    /// Ajusta el mapa para mostrar todas las coordenadas con el zoom apropiado
    private func fitMapToAllCoordinates(mapView: MKMapView, coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        
        // Si solo hay un punto, centrar con zoom fijo
        if coordinates.count == 1 {
            let region = MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            mapView.setRegion(region, animated: true)
            return
        }
        
        // Calcular bounding box
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLng = coordinates[0].longitude
        var maxLng = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLng = min(minLng, coord.longitude)
            maxLng = max(maxLng, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        // Calcular span con padding (50% extra para que los puntos no queden en el borde)
        let latDelta = (maxLat - minLat) * 1.5
        let lngDelta = (maxLng - minLng) * 1.5
        
        // Asegurar un span mínimo
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.003),
            longitudeDelta: max(lngDelta, 0.003)
        )
        
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TrackMapView
        
        init(_ parent: TrackMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(CaleiColors.accent)
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let salePointAnnotation = annotation as? TrackSalePointAnnotation else {
                return nil
            }
            
            let identifier = "SalePoint"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: salePointAnnotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
                view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                view?.annotation = salePointAnnotation
            }
            
            view?.markerTintColor = UIColor(CaleiColors.accent)
            view?.glyphImage = UIImage(systemName: "mappin")
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation as? TrackSalePointAnnotation {
                parent.onSalePointTap(annotation.salePoint)
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            if let salePointAnnotation = annotation as? TrackSalePointAnnotation {
                parent.onSalePointTap(salePointAnnotation.salePoint)
            }
        }
    }
}

// MARK: - Track Sale Point Annotation

class TrackSalePointAnnotation: MKPointAnnotation {
    let salePoint: SalePoint
    
    init(salePoint: SalePoint) {
        self.salePoint = salePoint
        super.init()
    }
}

#Preview {
    NavigationView {
        TrackDetailView(trackId: 1)
    }
}
