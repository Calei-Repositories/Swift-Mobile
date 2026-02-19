import SwiftUI
import MapKit

// MARK: - Zone Detail View

struct ZoneDetailView: View {
    let zone: GeoZone
    let initialSalePoints: [MarkedSalePoint]
    
    @State private var salePoints: [MarkedSalePoint]
    @State private var selectedSalePoint: MarkedSalePoint?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    private let adminService = AdminService()
    
    init(zone: GeoZone, salePoints: [MarkedSalePoint] = []) {
        self.zone = zone
        self.initialSalePoints = salePoints
        _salePoints = State(initialValue: salePoints)
        
        print("🗺️ ZoneDetailView init - Zone: \(zone.name)")
        print("🗺️ Sale points received: \(salePoints.count)")
    }
    
    private var zoneColor: Color {
        Color(hex: zone.color ?? "#4FD1C5") ?? CaleiColors.accent
    }
    
    var body: some View {
        ZStack {
            // Mapa con polígono y puntos
            ZoneMapWithPins(
                zone: zone,
                salePoints: salePoints,
                onPinTap: { point in
                    selectedSalePoint = point
                }
            )
            .ignoresSafeArea(edges: .bottom)
            
            // Header superior
            VStack {
                headerView
                Spacer()
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Cargando puntos...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSalePoint) { point in
            ZoneDetailInfoSheet(
                salePoint: point,
                onSaveComplete: { updatedPoint in
                    // Actualizar en la lista local
                    if let index = salePoints.firstIndex(where: { $0.id == updatedPoint.id }) {
                        salePoints[index] = updatedPoint
                    }
                    selectedSalePoint = updatedPoint
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .task {
            await loadSalePoints()
        }
    }
    
    private func loadSalePoints() async {
        // Si ya tenemos puntos, no recargar
        if !salePoints.isEmpty {
            isLoading = false
            return
        }
        
        print("🔄 Cargando puntos de venta para zona: \(zone.name) (ID: \(zone.id))")
        
        // Primero intentar obtener los sale points del detalle de zona
        // (el backend puede incluirlos en la respuesta de /zones/:id)
        do {
            let zonesService = ZonesService()
            let detailedZone = try await zonesService.getZone(id: zone.id)
            
            if let zoneSalePoints = detailedZone.salePoints, !zoneSalePoints.isEmpty {
                // Convertir ZoneSalePoint a MarkedSalePoint
                let converted = zoneSalePoints.compactMap { point -> MarkedSalePoint? in
                    guard let lat = point.actualLatitude, let lng = point.actualLongitude else { return nil }
                    return MarkedSalePoint(
                        id: point.id,
                        name: point.name ?? "Sin nombre",
                        latitude: lat,
                        longitude: lng,
                        zoneId: zone.id,
                        zoneName: zone.name
                    )
                }
                
                await MainActor.run {
                    salePoints = converted
                    isLoading = false
                    print("✅ Puntos cargados desde detalle de zona: \(converted.count)")
                }
                return
            }
        } catch {
            print("⚠️ No se pudieron cargar puntos desde detalle de zona: \(error)")
        }
        
        // Fallback: cargar todos los puntos y filtrar con ray-casting
        do {
            let allPoints = try await adminService.markedSalePointsMap(
                zoneId: nil,
                from: nil,
                to: nil,
                markedBy: nil,
                n: nil,
                s: nil,
                e: nil,
                w: nil,
                limit: 50000
            )
            
            let filtered = filterPointsInZone(allPoints)
            
            await MainActor.run {
                salePoints = filtered
                isLoading = false
                print("✅ Puntos cargados por ray-casting: \(filtered.count) de \(allPoints.count) totales")
            }
        } catch {
            print("❌ Error cargando puntos de venta: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    /// Filtra los puntos que están dentro del polígono de la zona usando ray-casting
    private func filterPointsInZone(_ points: [MarkedSalePoint]) -> [MarkedSalePoint] {
        print("🔍 Filtrando \(points.count) puntos para zona: \(zone.name)")
        print("🔍 Zone boundaryPoints: \(zone.boundaryPoints?.count ?? 0)")
        
        guard let boundaryPoints = zone.boundaryPoints, boundaryPoints.count >= 3 else {
            print("⚠️ Zona sin polígono válido - boundaryPoints nil o < 3")
            return []
        }
        
        let polygon = boundaryPoints.compactMap { $0.coordinate }
        print("🔍 Polygon coordinates: \(polygon.count)")
        
        guard polygon.count >= 3 else {
            print("⚠️ Polígono con menos de 3 coordenadas válidas")
            return []
        }
        
        // Mostrar primeros puntos del polígono para debug
        if let first = polygon.first {
            print("🔍 Primer punto polígono: (\(first.latitude), \(first.longitude))")
        }
        
        let filtered = points.filter { point in
            let coord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            return isPointInPolygon(point: coord, polygon: polygon)
        }
        
        print("🔍 Puntos dentro del polígono: \(filtered.count)")
        return filtered
    }
    
    /// Algoritmo de ray-casting para determinar si un punto está dentro de un polígono
    private func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
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
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zoneColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "map")
                        .foregroundColor(zoneColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(zone.name)
                    .font(.headline)
                    .foregroundColor(CaleiColors.dark)
                
                HStack(spacing: 8) {
                    Label("\(salePoints.count) puntos", systemImage: "mappin.circle")
                    
                    if zone.isDangerous == true {
                        Label("Peligrosa", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(CaleiColors.warning)
                    }
                }
                .font(.caption)
                .foregroundColor(CaleiColors.gray500)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [CaleiColors.background.opacity(0.95), CaleiColors.background.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Zone Map with Pins (UIViewRepresentable)

struct ZoneMapWithPins: UIViewRepresentable {
    let zone: GeoZone
    let salePoints: [MarkedSalePoint]
    let onPinTap: (MarkedSalePoint) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.pointOfInterestFilter = .excludingAll
        
        // Configurar estilo de mapa
        if #available(iOS 16.0, *) {
            mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        }
        
        // Agregar polígono de la zona
        let coords = zone.polygonCoordinates
        if coords.count >= 3 {
            var mutableCoords = coords
            let polygon = MKPolygon(coordinates: &mutableCoords, count: mutableCoords.count)
            mapView.addOverlay(polygon)
            
            // Centrar en el polígono
            let rect = polygon.boundingMapRect
            let padding = UIEdgeInsets(top: 100, left: 50, bottom: 50, right: 50)
            mapView.setVisibleMapRect(rect, edgePadding: padding, animated: false)
        }
        
        // Agregar puntos de venta
        addSalePointAnnotations(to: mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Actualizar anotaciones si cambian
        let existingAnnotations = mapView.annotations.compactMap { $0 as? ZoneSalePointAnnotation }
        let existingIds = Set(existingAnnotations.map { $0.salePoint.id })
        let newIds = Set(salePoints.map { $0.id })
        
        if existingIds != newIds {
            mapView.removeAnnotations(existingAnnotations)
            addSalePointAnnotations(to: mapView)
        }
    }
    
    private func addSalePointAnnotations(to mapView: MKMapView) {
        for point in salePoints {
            let annotation = ZoneSalePointAnnotation(salePoint: point)
            annotation.coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            annotation.title = point.name
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ZoneMapWithPins
        
        init(_ parent: ZoneMapWithPins) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                let zoneColor = UIColor(Color(hex: parent.zone.color ?? "#4FD1C5") ?? CaleiColors.accent)
                renderer.fillColor = zoneColor.withAlphaComponent(0.2)
                renderer.strokeColor = zoneColor
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let saleAnnotation = annotation as? ZoneSalePointAnnotation else { return nil }
            
            let identifier = "SalePointPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: saleAnnotation, reuseIdentifier: identifier)
                view?.canShowCallout = false
            } else {
                view?.annotation = saleAnnotation
            }
            
            view?.markerTintColor = UIColor(CaleiColors.accent)
            view?.glyphImage = UIImage(systemName: "storefront")
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            guard let saleAnnotation = annotation as? ZoneSalePointAnnotation else { return }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Deseleccionar inmediatamente para permitir selección repetida
            mapView.deselectAnnotation(annotation, animated: false)
            
            // Llamar callback
            parent.onPinTap(saleAnnotation.salePoint)
        }
    }
}

// MARK: - Zone Detail Info Sheet (Editable view)

struct ZoneDetailInfoSheet: View {
    let salePoint: MarkedSalePoint
    var onSaveComplete: ((MarkedSalePoint) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSuccessToast = false
    
    // Campos editables - Básico
    @State private var name: String = ""
    @State private var notes: String = ""
    
    // Campos editables - Contacto
    @State private var managerName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var hasWhatsApp: Bool = false
    @State private var openingHours: String = ""
    @State private var workingDays: String = ""
    
    // Campos editables - Exhibidor
    @State private var exhibitorType: String = ""
    @State private var supportType: String = ""
    @State private var installationNotes: String = ""
    
    init(salePoint: MarkedSalePoint, onSaveComplete: ((MarkedSalePoint) -> Void)? = nil) {
        self.salePoint = salePoint
        self.onSaveComplete = onSaveComplete
        
        _name = State(initialValue: salePoint.name)
        _notes = State(initialValue: salePoint.notes ?? "")
        _managerName = State(initialValue: salePoint.managerName ?? "")
        _phone = State(initialValue: salePoint.phone ?? "")
        _email = State(initialValue: salePoint.email ?? "")
        _hasWhatsApp = State(initialValue: salePoint.hasWhatsApp ?? false)
        _openingHours = State(initialValue: salePoint.openingHours ?? "")
        _workingDays = State(initialValue: salePoint.workingDays ?? "")
        _exhibitorType = State(initialValue: salePoint.exhibitorType ?? "")
        _supportType = State(initialValue: salePoint.supportType ?? "")
        _installationNotes = State(initialValue: salePoint.installationNotes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header info compacto
                headerView
                
                // Tabs
                Picker("Sección", selection: $selectedTab) {
                    Text("Básico").tag(0)
                    Text("Contacto").tag(1)
                    Text("Exhibidores").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Content - Usando Group en lugar de TabView para evitar problemas de renderizado
                Group {
                    switch selectedTab {
                    case 0:
                        basicInfoView
                    case 1:
                        contactInfoView
                    case 2:
                        exhibitorsView
                    default:
                        basicInfoView
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            .navigationTitle("Detalle del Punto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Cancelar") {
                            resetFields()
                            isEditing = false
                        }
                        .foregroundColor(CaleiColors.error)
                        .disabled(isSaving)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button {
                            saveChanges()
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .tint(CaleiColors.accent)
                            } else {
                                Text("Guardar")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(CaleiColors.accent)
                        .disabled(isSaving)
                    } else {
                        HStack(spacing: 12) {
                            Button {
                                isEditing = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(CaleiColors.accent)
                            }
                            
                            Button("Cerrar") {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .disabled(isSaving)
            .overlay {
                // Toast de éxito
                if showSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Guardado correctamente")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(CaleiColors.success)
                        .cornerRadius(25)
                        .shadow(radius: 4)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showSuccessToast)
                }
            }
            .alert("Error", isPresented: .constant(saveError != nil)) {
                Button("OK") {
                    saveError = nil
                }
            } message: {
                Text(saveError ?? "")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Icono
            ZStack {
                Circle()
                    .fill(CaleiColors.accent.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "storefront")
                    .font(.title2)
                    .foregroundColor(CaleiColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(salePoint.name)
                    .font(.headline)
                    .foregroundColor(CaleiColors.dark)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.caption)
                        .foregroundColor(CaleiColors.gray500)
                    Text("ID: \(salePoint.id)")
                        .font(.caption)
                        .foregroundColor(CaleiColors.gray500)
                    
                    Text("•")
                        .foregroundColor(CaleiColors.gray400)
                    
                    Text(salePoint.statusDisplayName)
                        .font(.caption)
                        .foregroundColor(CaleiColors.accent)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(CaleiColors.gray50)
    }
    
    // MARK: - Básico
    
    private var basicInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                infoCard(title: "Información General") {
                    if isEditing {
                        editableRow(icon: "storefront", label: "Nombre", text: $name)
                    } else {
                        infoRow(icon: "storefront", label: "Nombre", value: salePoint.name)
                    }
                    infoRow(icon: "number", label: "ID", value: "\(salePoint.id)")
                    infoRow(icon: "mappin.circle", label: "Coordenadas", value: String(format: "%.5f, %.5f", salePoint.latitude, salePoint.longitude))
                    
                    if let address = salePoint.address {
                        infoRow(icon: "location", label: "Dirección", value: address)
                    }
                    
                    infoRow(icon: "circle.fill", label: "Estado", value: salePoint.statusDisplayName)
                }
                
                infoCard(title: "Notas") {
                    if isEditing {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(CaleiColors.gray50)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(CaleiColors.gray200, lineWidth: 1)
                            )
                    } else if !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(CaleiColors.dark)
                    } else {
                        Text("Sin notas")
                            .font(.body)
                            .foregroundColor(CaleiColors.gray500)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Contacto
    
    private var contactInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                infoCard(title: "Datos de Contacto") {
                    if isEditing {
                        editableRow(icon: "person", label: "Encargado", text: $managerName, placeholder: "Nombre del encargado")
                        editableRow(icon: "phone", label: "Teléfono", text: $phone, placeholder: "Número de teléfono", keyboardType: .phonePad)
                        editableRow(icon: "envelope", label: "Email", text: $email, placeholder: "correo@ejemplo.com", keyboardType: .emailAddress)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "message")
                                .foregroundColor(CaleiColors.accent)
                                .frame(width: 24)
                            
                            Toggle("WhatsApp", isOn: $hasWhatsApp)
                                .tint(CaleiColors.accent)
                        }
                    } else {
                        if let managerName = salePoint.managerName, !managerName.isEmpty {
                            infoRow(icon: "person", label: "Encargado", value: managerName)
                        } else {
                            infoRow(icon: "person", label: "Encargado", value: "No especificado")
                        }
                        
                        if let phone = salePoint.phone, !phone.isEmpty {
                            infoRow(icon: "phone", label: "Teléfono", value: phone)
                        } else {
                            infoRow(icon: "phone", label: "Teléfono", value: "No especificado")
                        }
                        
                        if let email = salePoint.email, !email.isEmpty {
                            infoRow(icon: "envelope", label: "Email", value: email)
                        }
                        
                        infoRow(icon: "message", label: "WhatsApp", value: salePoint.hasWhatsApp == true ? "Sí" : "No")
                    }
                }
                
                infoCard(title: "Horarios de Atención") {
                    if isEditing {
                        editableRow(icon: "clock", label: "Horario", text: $openingHours, placeholder: "Ej: 9:00 - 18:00")
                        editableRow(icon: "calendar", label: "Días", text: $workingDays, placeholder: "Ej: Lunes a Viernes")
                    } else {
                        if let openingHours = salePoint.openingHours, !openingHours.isEmpty {
                            Text(openingHours)
                                .font(.body)
                                .foregroundColor(CaleiColors.dark)
                        } else if let from = salePoint.openingTimeFrom, let to = salePoint.openingTimeTo {
                            infoRow(icon: "clock", label: "Horario", value: "\(from) - \(to)")
                            if let days = salePoint.workingDays {
                                infoRow(icon: "calendar", label: "Días", value: days)
                            }
                        } else {
                            Text("No especificado")
                                .font(.body)
                                .foregroundColor(CaleiColors.gray500)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Exhibidores
    
    private var exhibitorsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                infoCard(title: "Exhibidores") {
                    if isEditing {
                        editableRow(icon: "rectangle.stack", label: "Tipo", text: $exhibitorType, placeholder: "Tipo de exhibidor")
                        editableRow(icon: "square.stack.3d.up", label: "Soporte", text: $supportType, placeholder: "Tipo de soporte")
                    } else {
                        if let exhibitorType = salePoint.exhibitorType, !exhibitorType.isEmpty {
                            infoRow(icon: "rectangle.stack", label: "Tipo", value: exhibitorType)
                        }
                        
                        if let supportType = salePoint.supportType, !supportType.isEmpty {
                            infoRow(icon: "square.stack.3d.up", label: "Soporte", value: supportType)
                        }
                        
                        if salePoint.exhibitorType == nil && salePoint.supportType == nil {
                            VStack(spacing: 12) {
                                Image(systemName: "rectangle.stack")
                                    .font(.largeTitle)
                                    .foregroundColor(CaleiColors.gray400)
                                
                                Text("Sin información de exhibidores")
                                    .font(.subheadline)
                                    .foregroundColor(CaleiColors.gray500)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    }
                }
                
                infoCard(title: "Notas de Instalación") {
                    if isEditing {
                        TextEditor(text: $installationNotes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(CaleiColors.gray50)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(CaleiColors.gray200, lineWidth: 1)
                            )
                    } else if let installationNotes = salePoint.installationNotes, !installationNotes.isEmpty {
                        Text(installationNotes)
                            .font(.body)
                            .foregroundColor(CaleiColors.dark)
                    } else {
                        Text("Sin notas de instalación")
                            .font(.body)
                            .foregroundColor(CaleiColors.gray500)
                    }
                }
                
                if let competition = salePoint.competition, !competition.isEmpty {
                    infoCard(title: "Competencia") {
                        Text(competition)
                            .font(.body)
                            .foregroundColor(CaleiColors.dark)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(CaleiColors.dark)
            
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(CaleiColors.accent)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(CaleiColors.gray500)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(CaleiColors.dark)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func editableRow(icon: String, label: String, text: Binding<String>, placeholder: String = "", keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(CaleiColors.accent)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(CaleiColors.gray500)
                .frame(width: 80, alignment: .leading)
            
            TextField(placeholder, text: text)
                .font(.subheadline)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // MARK: - Actions
    
    private func resetFields() {
        name = salePoint.name
        notes = salePoint.notes ?? ""
        managerName = salePoint.managerName ?? ""
        phone = salePoint.phone ?? ""
        email = salePoint.email ?? ""
        hasWhatsApp = salePoint.hasWhatsApp ?? false
        openingHours = salePoint.openingHours ?? ""
        workingDays = salePoint.workingDays ?? ""
        exhibitorType = salePoint.exhibitorType ?? ""
        supportType = salePoint.supportType ?? ""
        installationNotes = salePoint.installationNotes ?? ""
    }
    
    private func saveChanges() {
        let request = UpdateSalePointRequest(
            name: name.isEmpty ? nil : name,
            description: nil,
            hasWhatsApp: hasWhatsApp ? true : nil, // Solo enviar si es true
            notes: notes.isEmpty ? nil : notes,
            competition: nil,
            status: nil,
            managerName: managerName.isEmpty ? nil : managerName,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            openingTimeFrom: nil,
            openingTimeTo: nil,
            workingDays: workingDays.isEmpty ? nil : workingDays,
            exhibitorType: exhibitorType.isEmpty ? nil : exhibitorType,
            supportType: supportType.isEmpty ? nil : supportType,
            installationNotes: installationNotes.isEmpty ? nil : installationNotes,
            address: nil,
            openingHours: openingHours.isEmpty ? nil : openingHours
        )
        
        // Debug: Imprimir el request
        if let jsonData = try? JSONEncoder().encode(request),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Request body: \(jsonString)")
        }
        print("📤 Actualizando sale point ID: \(salePoint.id)")
        
        isSaving = true
        saveError = nil
        
        Task {
            do {
                // Llamar al API de admin para puntos marcados (acepta todos los campos)
                let endpoint = Endpoint(path: "/admin/marked-sale-points/\(salePoint.id)", method: .patch, body: request)
                let updated: MarkedSalePoint = try await APIClient.shared.request(endpoint, responseType: MarkedSalePoint.self)
                
                await MainActor.run {
                    isSaving = false
                    isEditing = false
                    showSuccessToast = true
                    
                    // Actualizar campos con datos del servidor
                    name = updated.name
                    notes = updated.notes ?? ""
                    managerName = updated.managerName ?? ""
                    phone = updated.phone ?? ""
                    email = updated.email ?? ""
                    hasWhatsApp = updated.hasWhatsApp ?? false
                    openingHours = updated.openingHours ?? ""
                    workingDays = updated.workingDays ?? ""
                    exhibitorType = updated.exhibitorType ?? ""
                    supportType = updated.supportType ?? ""
                    installationNotes = updated.installationNotes ?? ""
                    
                    // Notificar al padre que se actualizó
                    onSaveComplete?(updated)
                    
                    print("✅ Punto de venta actualizado: \(updated.name)")
                    
                    // Ocultar toast después de 2 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccessToast = false
                    }
                }
            } catch let apiError as APIError {
                // Si el endpoint admin no existe, intentar con el normal
                if case .httpStatus(let code) = apiError, code == 404 {
                    print("⚠️ Endpoint admin no encontrado, intentando fallback...")
                    await updateWithFallbackEndpoint(request: request)
                } else {
                    await MainActor.run {
                        isSaving = false
                        saveError = "Error al guardar: \(apiError.localizedDescription)"
                        print("❌ Error al actualizar punto de venta: \(apiError)")
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Error al guardar: \(error.localizedDescription)"
                    print("❌ Error al actualizar punto de venta: \(error)")
                }
            }
        }
    }
    
    /// Fallback usando endpoint normal (solo para campos básicos)
    private func updateWithFallbackEndpoint(request: UpdateSalePointRequest) async {
        do {
            let endpoint = Endpoint(path: "/sale-points/\(salePoint.id)", method: .patch, body: request)
            let updated: MarkedSalePoint = try await APIClient.shared.request(endpoint, responseType: MarkedSalePoint.self)
            
            await MainActor.run {
                isSaving = false
                isEditing = false
                showSuccessToast = true
                onSaveComplete?(updated)
                print("✅ Punto de venta actualizado (fallback): \(updated.name)")
            }
        } catch {
            await MainActor.run {
                isSaving = false
                saveError = "Error al guardar: \(error.localizedDescription)"
                print("❌ Error en fallback: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ZoneDetailView(
            zone: GeoZone(
                id: 1,
                name: "Zona Centro",
                isDangerous: false,
                isActive: true,
                boundaryPoints: [
                    BoundaryPoint(id: 1, latitude: -31.42, longitude: -64.18, order: 0),
                    BoundaryPoint(id: 2, latitude: -31.42, longitude: -64.19, order: 1),
                    BoundaryPoint(id: 3, latitude: -31.43, longitude: -64.19, order: 2),
                    BoundaryPoint(id: 4, latitude: -31.43, longitude: -64.18, order: 3)
                ]
            ),
            salePoints: []
        )
    }
}
