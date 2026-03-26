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
    let onSave: (String, Bool, [CLLocationCoordinate2D]?) async -> Bool
    // Optional bindings provided by the parent to show server-side validation errors
    @Binding var serverFieldErrors: [String: String]?
    @Binding var serverErrorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var isDangerous: Bool = false
    @State private var boundaryPoints: [CLLocationCoordinate2D] = []
    @State private var showMapEditor = false
    @State private var inlineSelectedPointIndex: Int? = nil
    @State private var isSaving: Bool = false
    @State private var saveErrorMessage: String? = nil
    @State private var localFieldErrors: [String: String]? = nil
    
    /// Color de la zona basado en si es peligrosa o no
    private var zoneColor: Color {
        isDangerous ? CaleiColors.error : CaleiColors.accent
    }
    
    init(mode: ZoneEditorMode,
         onSave: @escaping (String, Bool, [CLLocationCoordinate2D]?) async -> Bool,
         serverFieldErrors: Binding<[String: String]?> = .constant(nil),
         serverErrorMessage: Binding<String?> = .constant(nil)) {
        self.mode = mode
        self.onSave = onSave
        self._serverFieldErrors = serverFieldErrors
        self._serverErrorMessage = serverErrorMessage
        
        // Pre-llenar si es edición
        if case .edit(let zone) = mode {
            _name = State(initialValue: zone.name)
            _isDangerous = State(initialValue: zone.isDangerous ?? false)
            _boundaryPoints = State(initialValue: zone.polygonCoordinates)
        } else if case .create = mode {
            // Start map editor immediately when creating a new zone
            _showMapEditor = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top area: Name field aligned to app style
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombre de la zona")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray500)

                    // NOTE: Keep using typography and color tokens from Calei theme.
                    // Verify exact paddings, corner radius and border weight with the
                    // Brand Guidelines to ensure visual consistency.
                    TextField("Nombre de la zona", text: $name)
                        .font(CaleiTypography.body)
                        .padding(14)
                        .background(CaleiColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CaleiColors.gray200, lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .onChange(of: serverFieldErrors) { _, new in
                            localFieldErrors = new
                        }

                    // Small dangerous-zone toggle shown next to name for creation UX
                    HStack(spacing: 12) {
                        Button {
                            isDangerous.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isDangerous ? CaleiColors.error : CaleiColors.gray300, lineWidth: 2)
                                        .frame(width: 20, height: 20)

                                    if isDangerous {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(CaleiColors.error)
                                            .frame(width: 20, height: 20)
                                    }
                                }

                                Text("Zona peligrosa")
                                    .font(CaleiTypography.bodySmall)
                                    .foregroundColor(CaleiColors.dark)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    if let msg = localFieldErrors?["name"] {
                        Text(msg)
                            .font(CaleiTypography.caption)
                            .foregroundColor(CaleiColors.error)
                            .padding(.top, 6)
                    }
                }
                .padding(16)

                // Central area: large map preview or inline map editor
                ZStack(alignment: .topTrailing) {
                    if showMapEditor {
                        // Inline editable map (no separate sheet) — preserves drawing logic
                        ZoneDrawingMapView(
                            initialPoints: boundaryPoints,
                            color: zoneColor,
                            inline: true,
                            onSave: { points in
                                boundaryPoints = points
                                inlineSelectedPointIndex = nil
                                showMapEditor = false
                            },
                            onCancel: {
                                inlineSelectedPointIndex = nil
                                showMapEditor = false
                            },
                            externalPoints: $boundaryPoints,
                            onSelect: { idx in inlineSelectedPointIndex = idx },
                            externalSelectedIndex: $inlineSelectedPointIndex,
                            showControls: false
                        )
                            .frame(height: 520)
                        .cornerRadius(24)
                        .padding(.horizontal, 16)
                    } else {
                        // Preview mode (non-interactive) — tapping enters inline edit
                        Group {
                            if boundaryPoints.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "map")
                                        .font(.system(size: 40))
                                        .foregroundColor(CaleiColors.gray400)

                                    Text("Sin perímetro definido")
                                        .font(CaleiTypography.bodySmall)
                                        .foregroundColor(CaleiColors.gray500)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 360)
                                .background(CaleiColors.systemSecondarySurface)
                                .cornerRadius(24)
                            } else {
                                ZonePreviewMap(
                                    points: boundaryPoints,
                                    uiColor: UIColor(zoneColor)
                                )
                                .frame(height: 360)
                                .cornerRadius(24)
                            }
                        }
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            // Allow entering edit mode immediately by tapping the preview
                            showMapEditor = true
                        }
                    }
                }
                .padding(.bottom, 12)

                // Show Zona peligrosa only when not editing map inline
                if !showMapEditor {
                    VStack(spacing: 12) {
                        // Keep original Zona peligrosa control (preserve logic)
                        Button {
                            isDangerous.toggle()
                        } label: {
                            HStack(spacing: 12) {
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
                        .padding(.horizontal, 16)
                    }
                }

                Spacer()

                // Bottom action area while editing: show either selection actions or default actions
                VStack(spacing: 12) {
                    if showMapEditor {
                        if let idx = inlineSelectedPointIndex {
                            // Selected point actions (matches the attached art)
                            HStack(spacing: 12) {
                                Text("Punto \(idx + 1)")
                                    .font(CaleiTypography.body)
                                    .foregroundColor(CaleiColors.dark)
                                    .padding(.leading, 16)

                                Spacer()

                                Button {
                                    // Eliminar punto
                                    if idx < boundaryPoints.count {
                                        boundaryPoints.remove(at: idx)
                                    }
                                    inlineSelectedPointIndex = nil
                                } label: {
                                    Text("Eliminar")
                                        .font(CaleiTypography.button)
                                        .foregroundColor(CaleiColors.error)
                                        .frame(minWidth: 100)
                                        .padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(CaleiColors.cardBackground))
                                }

                                Button {
                                    inlineSelectedPointIndex = nil
                                } label: {
                                    Text("Cerrar")
                                        .font(CaleiTypography.button)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 18)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(CaleiColors.accent))
                                }
                            }
                            .padding(.horizontal, 16)
                        } else {
                            // Default editing actions
                            Button {
                                boundaryPoints.removeAll()
                            } label: {
                                Text("Limpiar todo")
                                    .font(CaleiTypography.button)
                                    .foregroundColor(CaleiColors.dark)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(CaleiColors.cardBackground)
                                    )
                            }
                            .padding(.horizontal, 16)

                            HStack(spacing: 12) {
                                Button {
                                    // Cancel editing
                                    showMapEditor = false
                                    inlineSelectedPointIndex = nil
                                } label: {
                                    Text("Cancelar")
                                        .font(CaleiTypography.button)
                                        .foregroundColor(CaleiColors.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(CaleiColors.accent, lineWidth: 1)
                                        )
                                }

                                                Button {
                                                    Task { save() }
                                                } label: {
                                                    if isSaving {
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                            .frame(maxWidth: .infinity)
                                                            .padding(.vertical, 14)
                                                            .background(RoundedRectangle(cornerRadius: 14).fill(CaleiColors.accent))
                                                    } else {
                                                        Text(mode.buttonText)
                                                            .font(CaleiTypography.button)
                                                            .foregroundColor(.white)
                                                            .frame(maxWidth: .infinity)
                                                            .padding(.vertical, 14)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 14)
                                                                    .fill(CaleiColors.accent)
                                                            )
                                                    }
                                                }
                                                .disabled(isSaving)
                            }
                            .padding(.horizontal, 16)
                        }
                    } else {
                        // Non-editing bottom (default form actions)
                        Button {
                            boundaryPoints.removeAll()
                        } label: {
                            Text("Limpiar todo")
                                .font(CaleiTypography.button)
                                .foregroundColor(CaleiColors.dark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(CaleiColors.cardBackground)
                                )
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancelar")
                                    .font(CaleiTypography.button)
                                    .foregroundColor(CaleiColors.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(CaleiColors.accent, lineWidth: 1)
                                    )
                            }

                            Button {
                                Task { save() }
                            } label: {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(CaleiColors.accent))
                                } else {
                                    Text(mode.buttonText)
                                        .font(CaleiTypography.button)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(CaleiColors.accent)
                                        )
                                }
                            }
                            .disabled(isSaving)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
            .background(CaleiColors.systemSurface.ignoresSafeArea())
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
            .alert(isPresented: Binding(get: { saveErrorMessage != nil }, set: { if !$0 { saveErrorMessage = nil } })) {
                saveErrorAlert
            }
            // Map editor now shown inline; no sheet presentation
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
                            uiColor: UIColor(zoneColor)
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
        // Validate name first and show friendly alert instead of silently blocking
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveErrorMessage = "Por favor ingresa un nombre para la zona."
            return
        }

        // Validate perimeter has at least 3 points before sending to backend
        if boundaryPoints.count < 3 {
            saveErrorMessage = "La zona debe tener al menos 3 puntos en el perímetro."
            return
        }
        // Validate name length
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 100 {
            saveErrorMessage = "El nombre no puede superar 100 caracteres."
            return
        }
        // Validate coordinate ranges for each boundary point
        for (i, p) in boundaryPoints.enumerated() {
            if p.latitude < -90 || p.latitude > 90 {
                saveErrorMessage = "Latitud inválida en el punto \(i + 1)."
                return
            }
            if p.longitude < -180 || p.longitude > 180 {
                saveErrorMessage = "Longitud inválida en el punto \(i + 1)."
                return
            }
        }
        // Dismiss keyboard to avoid Auto Layout conflicts when presenting alerts
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        isSaving = true
        Task {
            let success = await onSave(
                name,
                isDangerous,
                boundaryPoints.isEmpty ? nil : boundaryPoints
            )

            await MainActor.run {
                isSaving = false
                if success {
                    dismiss()
                } else {
                    // Prefer server-provided message if available
                    if let serverMsg = serverErrorMessage {
                        saveErrorMessage = serverMsg
                    } else {
                        saveErrorMessage = viewModelErrorFallback()
                    }
                    // Reflect any field errors into the local state
                    localFieldErrors = serverFieldErrors
                }
            }
        }
    }

    // Fallback message used if the onSave closure did not provide details
    private func viewModelErrorFallback() -> String {
        return "No se pudo guardar la zona. Por favor intenta de nuevo."
    }

    // Show alert on save failure
    private var saveErrorAlert: Alert {
        Alert(title: Text("Error"), message: Text(saveErrorMessage ?? ""), dismissButton: .default(Text("Cerrar"), action: { saveErrorMessage = nil }))
    }
}

// MARK: - Zone Preview Map

struct ZonePreviewMap: UIViewRepresentable {
    let points: [CLLocationCoordinate2D]
    let uiColor: UIColor
    
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
        // Mantener actualizado el color en el coordinator para que el renderer use el color actual
        context.coordinator.uiColor = uiColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(uiColor: uiColor)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var uiColor: UIColor

        init(uiColor: UIColor) {
            self.uiColor = uiColor
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = uiColor.withAlphaComponent(0.3)
                renderer.strokeColor = uiColor
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Preview

#Preview("Create") {
    ZoneEditorSheet(mode: .create, onSave: { _, _, _ in
        return true
    }, serverFieldErrors: .constant(nil), serverErrorMessage: .constant(nil))
}
