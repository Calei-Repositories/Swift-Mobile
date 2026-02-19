import SwiftUI
import MapKit

// MARK: - Zone Editor Mode

enum ZoneEditorMode {
    case create
    case edit(GeoZone)
    
    var title: String {
        switch self {
        case .create: return "Nueva Zona"
        case .edit: return "Editar Zona"
        }
    }
    
    var buttonText: String {
        switch self {
        case .create: return "Crear Zona"
        case .edit: return "Guardar Cambios"
        }
    }
}

// MARK: - Zone Editor Sheet

struct ZoneEditorSheet: View {
    let mode: ZoneEditorMode
    let onSave: (String, Bool, [CLLocationCoordinate2D]?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var isDangerous: Bool = false
    @State private var boundaryPoints: [CLLocationCoordinate2D] = []
    @State private var showMapEditor = false
    
    /// Color de la zona basado en si es peligrosa o no
    private var zoneColor: Color {
        isDangerous ? CaleiColors.error : CaleiColors.accent
    }
    
    init(mode: ZoneEditorMode, onSave: @escaping (String, Bool, [CLLocationCoordinate2D]?) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-llenar si es edición
        if case .edit(let zone) = mode {
            _name = State(initialValue: zone.name)
            _isDangerous = State(initialValue: zone.isDangerous ?? false)
            _boundaryPoints = State(initialValue: zone.polygonCoordinates)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Formulario básico
                    formSection
                    
                    // Preview del mapa
                    mapPreviewSection
                    
                    // Botón guardar
                    saveButton
                }
                .padding()
            }
            .background(CaleiColors.gray50)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(CaleiColors.gray500)
                }
            }
            .sheet(isPresented: $showMapEditor) {
                ZoneDrawingMapView(
                    initialPoints: boundaryPoints,
                    color: zoneColor
                ) { points in
                    boundaryPoints = points
                    showMapEditor = false
                }
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Información")
                .font(CaleiTypography.h4)
                .foregroundColor(CaleiColors.dark)
            
            VStack(spacing: 16) {
                // Nombre
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nombre *")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)
                    
                    TextField("Ej: Zona Norte", text: $name)
                        .font(CaleiTypography.body)
                        .padding(12)
                        .background(CaleiColors.background)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(CaleiColors.gray200, lineWidth: 1)
                        )
                }
                
                // Checkbox Zona Peligrosa
                Button {
                    isDangerous.toggle()
                } label: {
                    HStack(spacing: 12) {
                        // Checkbox
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isDangerous ? CaleiColors.error : CaleiColors.gray300, lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if isDangerous {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(CaleiColors.error)
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Zona peligrosa")
                                .font(CaleiTypography.body)
                                .foregroundColor(CaleiColors.dark)
                            
                            Text("Marcar si es una zona de riesgo o restricción")
                                .font(CaleiTypography.caption)
                                .foregroundColor(CaleiColors.gray500)
                        }
                        
                        Spacer()
                        
                        // Indicador de color
                        Circle()
                            .fill(zoneColor)
                            .frame(width: 20, height: 20)
                    }
                    .padding(12)
                    .background(isDangerous ? CaleiColors.error.opacity(0.1) : CaleiColors.background)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isDangerous ? CaleiColors.error.opacity(0.3) : CaleiColors.gray200, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(CaleiColors.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Map Preview Section
    
    private var mapPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Perímetro")
                    .font(CaleiTypography.h4)
                    .foregroundColor(CaleiColors.dark)
                
                Spacer()
                
                Text("\(boundaryPoints.count) puntos")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray500)
            }
            
            VStack(spacing: 12) {
                // Preview del mapa
                ZStack {
                    if boundaryPoints.isEmpty {
                        // Estado vacío
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(CaleiColors.gray400)
                            
                            Text("Sin perímetro definido")
                                .font(CaleiTypography.bodySmall)
                                .foregroundColor(CaleiColors.gray500)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(CaleiColors.gray100)
                        .cornerRadius(12)
                    } else {
                        // Mini mapa con el polígono
                        ZonePreviewMap(
                            points: boundaryPoints,
                            color: zoneColor
                        )
                        .frame(height: 180)
                        .cornerRadius(12)
                    }
                }
                
                // Botón para editar en mapa
                Button {
                    showMapEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: boundaryPoints.isEmpty ? "plus.circle" : "pencil")
                        Text(boundaryPoints.isEmpty ? "Dibujar perímetro" : "Editar perímetro")
                    }
                    .font(CaleiTypography.button)
                    .foregroundColor(CaleiColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(CaleiColors.accentSoft)
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .background(CaleiColors.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                Text(mode.buttonText)
            }
            .font(CaleiTypography.button)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if name.isEmpty {
                        CaleiColors.gray400
                    } else {
                        CaleiColors.accentGradient
                    }
                }
            )
            .cornerRadius(14)
        }
        .disabled(name.isEmpty)
    }
    
    // MARK: - Actions
    
    private func save() {
        onSave(
            name,
            isDangerous,
            boundaryPoints.isEmpty ? nil : boundaryPoints
        )
        dismiss()
    }
}

// MARK: - Zone Preview Map

struct ZonePreviewMap: UIViewRepresentable {
    let points: [CLLocationCoordinate2D]
    let color: Color
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        guard points.count >= 3 else { return }
        
        var coords = points
        let polygon = MKPolygon(coordinates: &coords, count: coords.count)
        mapView.addOverlay(polygon)
        
        // Ajustar región
        let rect = polygon.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(color: color)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let color: Color
        
        init(color: Color) {
            self.color = color
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor(color).withAlphaComponent(0.3)
                renderer.strokeColor = UIColor(color)
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Preview

#Preview("Create") {
    ZoneEditorSheet(mode: .create) { _, _, _ in }
}
