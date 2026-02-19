import SwiftUI
import MapKit

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Zone Drawing Map View

struct ZoneDrawingMapView: View {
    let initialPoints: [CLLocationCoordinate2D]
    let color: Color
    let onSave: ([CLLocationCoordinate2D]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var points: [CLLocationCoordinate2D] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var selectedPointIndex: Int?
    @State private var showClearConfirmation = false
    @State private var draggingPointIndex: Int?
    
    init(
        initialPoints: [CLLocationCoordinate2D],
        color: Color,
        onSave: @escaping ([CLLocationCoordinate2D]) -> Void
    ) {
        self.initialPoints = initialPoints
        self.color = color
        self.onSave = onSave
        _points = State(initialValue: initialPoints)
        
        // Si hay puntos iniciales, centrar en ellos
        if !initialPoints.isEmpty {
            let centerLat = initialPoints.reduce(0) { $0 + $1.latitude } / Double(initialPoints.count)
            let centerLng = initialPoints.reduce(0) { $0 + $1.longitude } / Double(initialPoints.count)
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Mapa interactivo
                DrawingMapRepresentable(
                    region: $region,
                    points: $points,
                    selectedPointIndex: $selectedPointIndex,
                    draggingPointIndex: $draggingPointIndex,
                    color: color
                )
                .ignoresSafeArea(edges: .bottom)
                
                // Instrucciones y controles superpuestos
                VStack {
                    // Instrucciones
                    instructionsBar
                    
                    Spacer()
                    
                    // Controles inferiores
                    bottomControls
                }
            }
            .navigationTitle("Dibujar Perímetro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(CaleiColors.gray500)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        // Organizar puntos antes de guardar para evitar intersecciones
                        let organizedPoints = PolygonOrganizer.organizePoints(points)
                        onSave(organizedPoints)
                    }
                    .font(.headline)
                    .foregroundColor(points.count >= 3 ? CaleiColors.accent : CaleiColors.gray400)
                    .disabled(points.count < 3)
                }
            }
            .confirmationDialog(
                "¿Borrar todos los puntos?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Borrar todo", role: .destructive) {
                    points.removeAll()
                    selectedPointIndex = nil
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
    
    // MARK: - Instructions Bar
    
    private var instructionsBar: some View {
        HStack(spacing: 8) {
            Image(systemName: draggingPointIndex != nil ? "hand.draw.fill" : "hand.tap.fill")
                .font(.system(size: 14))
            
            Text(draggingPointIndex != nil ? "Arrastrá para mover el punto" : "Tocá para agregar • Mantené presionado para mover")
                .font(CaleiTypography.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(draggingPointIndex != nil ? CaleiColors.accent.opacity(0.9) : Color.black.opacity(0.7))
        )
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Info de puntos
            HStack {
                Label("\(points.count) puntos", systemImage: "mappin.circle.fill")
                    .font(CaleiTypography.bodySmall)
                    .foregroundColor(CaleiColors.dark)
                
                Spacer()
                
                if points.count >= 3 {
                    Label("Polígono válido", systemImage: "checkmark.circle.fill")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.success)
                } else {
                    Label("Mínimo 3 puntos", systemImage: "exclamationmark.circle")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.warning)
                }
            }
            
            // Botones de acción
            HStack(spacing: 12) {
                // Deshacer último punto
                Button {
                    if !points.isEmpty {
                        points.removeLast()
                        selectedPointIndex = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Deshacer")
                    }
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(points.isEmpty ? CaleiColors.gray400 : CaleiColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CaleiColors.accentSoft)
                    .cornerRadius(10)
                }
                .disabled(points.isEmpty)
                
                // Eliminar punto seleccionado
                Button {
                    if let index = selectedPointIndex, index < points.count {
                        points.remove(at: index)
                        selectedPointIndex = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Eliminar")
                    }
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(selectedPointIndex == nil ? CaleiColors.gray400 : CaleiColors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedPointIndex == nil ? CaleiColors.gray100 : CaleiColors.errorSoft)
                    .cornerRadius(10)
                }
                .disabled(selectedPointIndex == nil)
                
                // Limpiar todo
                Button {
                    showClearConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("Limpiar")
                    }
                    .font(CaleiTypography.buttonSmall)
                    .foregroundColor(points.isEmpty ? CaleiColors.gray400 : CaleiColors.gray600)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CaleiColors.gray100)
                    .cornerRadius(10)
                }
                .disabled(points.isEmpty)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Polygon Organizer

/// Utilidades para organizar puntos y formar polígonos válidos sin intersecciones
enum PolygonOrganizer {
    
    /// Reordena los puntos para formar un polígono simple (sin auto-intersecciones)
    /// Usa ordenamiento por ángulo polar desde el centroide
    static func organizePoints(_ points: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard points.count >= 3 else { return points }
        
        // Calcular el centroide
        let centroidLat = points.reduce(0.0) { $0 + $1.latitude } / Double(points.count)
        let centroidLng = points.reduce(0.0) { $0 + $1.longitude } / Double(points.count)
        
        // Ordenar por ángulo polar respecto al centroide
        // Esto siempre produce un polígono simple (sin auto-intersecciones)
        let sorted = points.sorted { p1, p2 in
            let angle1 = atan2(p1.latitude - centroidLat, p1.longitude - centroidLng)
            let angle2 = atan2(p2.latitude - centroidLat, p2.longitude - centroidLng)
            return angle1 < angle2
        }
        
        return sorted
    }
}

// MARK: - Drawing Map Representable

struct DrawingMapRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var points: [CLLocationCoordinate2D]
    @Binding var selectedPointIndex: Int?
    @Binding var draggingPointIndex: Int?
    let color: Color
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        
        // Tap gesture para agregar puntos
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Long press gesture para seleccionar punto a mover
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        longPressGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(longPressGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coord = context.coordinator
        let isDragging = draggingPointIndex != nil
        let dragJustEnded = !isDragging && coord.lastDraggingIndex != nil
        
        // CASO 1: Durante el arrastre - solo mover anotación (sin tocar overlays)
        if isDragging, let dragIndex = draggingPointIndex {
            if let annotation = coord.pointAnnotations[safe: dragIndex] {
                annotation.coordinate = points[dragIndex]
            }
            coord.lastDraggingIndex = dragIndex
            return
        }
        
        // CASO 2: Se soltó el punto - recalcular polígono
        if dragJustEnded {
            coord.lastDraggingIndex = nil
            coord.cachedOrganizedPoints = points.count >= 3 ? PolygonOrganizer.organizePoints(points) : []
            updatePolygonOverlay(mapView, context: context)
            return
        }
        
        // CASO 3: Cambió la cantidad de puntos - recrear todo
        if points.count != coord.pointAnnotations.count {
            coord.lastDraggingIndex = nil
            
            // Remover anotaciones viejas
            mapView.removeAnnotations(coord.pointAnnotations)
            coord.pointAnnotations.removeAll()
            
            // Crear nuevas anotaciones
            for (index, point) in points.enumerated() {
                let annotation = PointAnnotation(
                    index: index,
                    isSelected: selectedPointIndex == index,
                    isDragging: false
                )
                annotation.coordinate = point
                coord.pointAnnotations.append(annotation)
                mapView.addAnnotation(annotation)
            }
            
            // Actualizar polígono
            coord.cachedOrganizedPoints = points.count >= 3 ? PolygonOrganizer.organizePoints(points) : []
            updatePolygonOverlay(mapView, context: context)
            coord.lastSelectedIndex = selectedPointIndex
            return
        }
        
        // CASO 4: Cambió la selección
        if selectedPointIndex != coord.lastSelectedIndex {
            for annotation in coord.pointAnnotations {
                annotation.isSelected = annotation.index == selectedPointIndex
                if let view = mapView.view(for: annotation) {
                    let size: CGFloat = annotation.isSelected ? 24 : 18
                    let color = annotation.isSelected ? UIColor(CaleiColors.error) : UIColor(color)
                    view.image = coord.getCachedPointImage(size: size, color: color, isDragging: false, isSelected: annotation.isSelected)
                }
            }
            coord.lastSelectedIndex = selectedPointIndex
        }
    }
    
    private func updatePolygonOverlay(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        if points.count >= 3 {
            var coords = context.coordinator.cachedOrganizedPoints
            if !coords.isEmpty {
                let polygon = MKPolygon(coordinates: &coords, count: coords.count)
                mapView.addOverlay(polygon)
            }
        } else if points.count == 2 {
            var coords = points
            let polyline = MKPolyline(coordinates: &coords, count: coords.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: DrawingMapRepresentable
        private var isDragging = false
        
        // Referencias directas a anotaciones para acceso O(1)
        var pointAnnotations: [PointAnnotation] = []
        var cachedOrganizedPoints: [CLLocationCoordinate2D] = []
        var lastSelectedIndex: Int? = nil
        var lastDraggingIndex: Int? = nil
        
        // Cache de imágenes pre-renderizadas
        private var pointImageCache: [String: UIImage] = [:]
        
        init(_ parent: DrawingMapRepresentable) {
            self.parent = parent
        }
        
        func getCachedPointImage(size: CGFloat, color: UIColor, isDragging: Bool, isSelected: Bool) -> UIImage {
            let key = "\(Int(size))-\(color.hash)-\(isDragging)-\(isSelected)"
            
            if let cached = pointImageCache[key] {
                return cached
            }
            
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            let image = renderer.image { ctx in
                let rect = CGRect(x: 2, y: 2, width: size - 4, height: size - 4)
                
                // Sombra
                ctx.cgContext.setShadow(offset: CGSize(width: 0, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.3).cgColor)
                
                // Círculo con borde
                color.setFill()
                UIColor.white.setStroke()
                let path = UIBezierPath(ovalIn: rect)
                path.lineWidth = 2
                path.fill()
                path.stroke()
            }
            
            pointImageCache[key] = image
            return image
        }
        
        // Permitir gestos simultáneos
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            guard !isDragging else { return }
            
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            // Verificar si tocó cerca de un punto existente
            for (index, point) in parent.points.enumerated() {
                let pointLocation = mapView.convert(point, toPointTo: mapView)
                let distance = hypot(location.x - pointLocation.x, location.y - pointLocation.y)
                
                if distance < 40 {
                    // Seleccionar/deseleccionar punto existente
                    parent.selectedPointIndex = parent.selectedPointIndex == index ? nil : index
                    return
                }
            }
            
            // Agregar nuevo punto
            parent.points.append(coordinate)
            parent.selectedPointIndex = nil
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            
            let location = gesture.location(in: mapView)
            
            switch gesture.state {
            case .began:
                // Buscar punto cercano para comenzar drag
                for (index, point) in parent.points.enumerated() {
                    let pointLocation = mapView.convert(point, toPointTo: mapView)
                    let distance = hypot(location.x - pointLocation.x, location.y - pointLocation.y)
                    
                    if distance < 50 {
                        isDragging = true
                        parent.draggingPointIndex = index
                        mapView.isScrollEnabled = false
                        mapView.isZoomEnabled = false
                        
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        break
                    }
                }
                
            case .changed:
                if isDragging, let draggingIndex = parent.draggingPointIndex {
                    parent.points[draggingIndex] = mapView.convert(location, toCoordinateFrom: mapView)
                }
                
            case .ended, .cancelled:
                isDragging = false
                parent.draggingPointIndex = nil
                mapView.isScrollEnabled = true
                mapView.isZoomEnabled = true
                
            default:
                break
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor(parent.color).withAlphaComponent(0.2)
                renderer.strokeColor = UIColor(parent.color)
                renderer.lineWidth = 3
                return renderer
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(parent.color)
                renderer.lineWidth = 3
                renderer.lineDashPattern = [5, 5]
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pointAnnotation = annotation as? PointAnnotation else { return nil }
            
            let identifier = "PointAnnotation"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if view == nil {
                view = MKAnnotationView(annotation: pointAnnotation, reuseIdentifier: identifier)
                view?.canShowCallout = false
            } else {
                view?.annotation = pointAnnotation
            }
            
            // Determinar tamaño y color
            let baseSize: CGFloat = 18
            let size: CGFloat = pointAnnotation.isDragging ? 28 : (pointAnnotation.isSelected ? 24 : baseSize)
            
            let color: UIColor
            if pointAnnotation.isDragging {
                color = UIColor(CaleiColors.accent)
            } else if pointAnnotation.isSelected {
                color = UIColor(CaleiColors.error)
            } else {
                color = UIColor(parent.color)
            }
            
            // Usar imagen cacheada para mejor rendimiento
            view?.image = getCachedPointImage(size: size, color: color, isDragging: pointAnnotation.isDragging, isSelected: pointAnnotation.isSelected)
            view?.centerOffset = CGPoint(x: 0, y: -size/2)
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            if let pointAnnotation = annotation as? PointAnnotation {
                parent.selectedPointIndex = pointAnnotation.index
                mapView.deselectAnnotation(annotation, animated: false)
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

// MARK: - Point Annotation

class PointAnnotation: MKPointAnnotation {
    let index: Int
    var isSelected: Bool
    var isDragging: Bool
    
    init(index: Int, isSelected: Bool, isDragging: Bool = false) {
        self.index = index
        self.isSelected = isSelected
        self.isDragging = isDragging
        super.init()
    }
}

// MARK: - Error Soft Color Extension

extension CaleiColors {
    static var errorSoft: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 1)
                : UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1)
        })
    }
}

// MARK: - Preview

#Preview {
    ZoneDrawingMapView(
        initialPoints: [],
        color: CaleiColors.accent
    ) { _ in }
}
