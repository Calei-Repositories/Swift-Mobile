import SwiftUI
import MapKit

struct AddSalePointView: View {
    @StateObject private var viewModel: AddSalePointViewModel
    @Environment(\.dismiss) private var dismiss
    
    var onSaved: ((SalePoint) -> Void)?
    
    // Estado para el modo de selección de ubicación
    @State private var locationMode: LocationSelectionMode = .currentLocation
    @State private var showMapSelector = false
    @State private var selectedMapCoordinate: CLLocationCoordinate2D?
    
    let caleiDark = Color(red: 0.118, green: 0.145, blue: 0.188)
    let caleiAccent = Color(red: 0.310, green: 0.820, blue: 0.773)
    let gray400 = Color(red: 0.580, green: 0.639, blue: 0.722)
    
    enum LocationSelectionMode: String, CaseIterable {
        case currentLocation = "Mi ubicación"
        case mapSelection = "Seleccionar en mapa"
    }
    
    init(trackId: Int, onSaved: ((SalePoint) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AddSalePointViewModel(trackId: trackId))
        self.onSaved = onSaved
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Información básica
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre del punto de venta *")
                            .font(.caption)
                            .foregroundColor(gray400)
                        TextField("Ej: Kiosco Don Pepe", text: $viewModel.name)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dirección")
                            .font(.caption)
                            .foregroundColor(gray400)
                        TextField("Ej: Av. Corrientes 1234", text: $viewModel.address)
                    }
                } header: {
                    Text("Información básica")
                }
                
                // Ubicación - Con selector de modo
                Section {
                    // Selector de modo
                    Picker("Modo de ubicación", selection: $locationMode) {
                        ForEach(LocationSelectionMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    
                    // Contenido según el modo
                    switch locationMode {
                    case .currentLocation:
                        currentLocationView
                        
                    case .mapSelection:
                        mapSelectionView
                    }
                } header: {
                    Text("Ubicación")
                }
                
                // Contacto
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre de contacto")
                            .font(.caption)
                            .foregroundColor(gray400)
                        TextField("Ej: Juan Pérez", text: $viewModel.contactName)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Teléfono")
                            .font(.caption)
                            .foregroundColor(gray400)
                        TextField("Ej: 11-2345-6789", text: $viewModel.phone)
                            .keyboardType(.phonePad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(gray400)
                        TextField("Ej: contacto@email.com", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                } header: {
                    Text("Contacto")
                }
                
                // Estado y Zona
                Section {
                    if !viewModel.statuses.isEmpty {
                        Picker("Estado", selection: $viewModel.selectedStatusId) {
                            Text("Sin estado").tag(nil as Int?)
                            ForEach(viewModel.statuses) { status in
                                Text(status.name).tag(status.id as Int?)
                            }
                        }
                    }
                    
                    if !viewModel.zones.isEmpty {
                        Picker("Zona", selection: $viewModel.selectedZoneId) {
                            Text("Sin zona").tag(nil as Int?)
                            ForEach(viewModel.zones) { zone in
                                Text(zone.name).tag(zone.id as Int?)
                            }
                        }
                    }
                } header: {
                    Text("Clasificación")
                }
                
                // Notas
                Section {
                    TextField("Notas adicionales", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notas")
                }
                
                // Error
                if case let .error(message) = viewModel.state {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                
                // Botón guardar
                Section {
                    Button {
                        Task {
                            // Actualizar coordenadas según el modo
                            updateViewModelCoordinates()
                            
                            if let salePoint = await viewModel.saveSalePoint() {
                                onSaved?(salePoint)
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.state == .saving {
                                ProgressView()
                                    .tint(caleiDark)
                            } else {
                                Text("Guardar punto de venta")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .foregroundColor(caleiDark)
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(caleiAccent)
                    .disabled(!viewModel.isFormValid || viewModel.state == .saving)
                }
            }
            .navigationTitle("Nuevo punto de venta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadOptions()
            }
            .fullScreenCover(isPresented: $showMapSelector) {
                MapPointSelectorView(
                    initialCoordinate: selectedMapCoordinate ?? viewModel.currentLocation?.coordinate,
                    onSelect: { coordinate in
                        selectedMapCoordinate = coordinate
                        showMapSelector = false
                    },
                    onCancel: {
                        showMapSelector = false
                    }
                )
            }
        }
    }
    
    // MARK: - Vista de ubicación actual
    
    private var currentLocationView: some View {
        Group {
            if let location = viewModel.currentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(caleiAccent)
                    VStack(alignment: .leading) {
                        Text("Ubicación detectada")
                            .font(.subheadline)
                        Text("\(location.coordinate.latitude, specifier: "%.6f"), \(location.coordinate.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(gray400)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                HStack {
                    Image(systemName: "location.slash")
                        .foregroundColor(.orange)
                    Text("Obteniendo ubicación...")
                        .font(.subheadline)
                    Spacer()
                    ProgressView()
                }
            }
        }
    }
    
    // MARK: - Vista de selección en mapa
    
    private var mapSelectionView: some View {
        VStack(spacing: 12) {
            // Mostrar coordenadas seleccionadas
            if let coordinate = selectedMapCoordinate {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(caleiAccent)
                    VStack(alignment: .leading) {
                        Text("Punto seleccionado")
                            .font(.subheadline)
                        Text("\(coordinate.latitude, specifier: "%.6f"), \(coordinate.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(gray400)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else {
                HStack {
                    Image(systemName: "mappin.slash")
                        .foregroundColor(.orange)
                    Text("Ningún punto seleccionado")
                        .font(.subheadline)
                        .foregroundColor(gray400)
                    Spacer()
                }
            }
            
            // Botón para abrir el mapa
            Button {
                showMapSelector = true
            } label: {
                HStack {
                    Image(systemName: "map")
                    Text(selectedMapCoordinate == nil ? "Seleccionar en el mapa" : "Cambiar ubicación")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(caleiAccent.opacity(0.15))
                .foregroundColor(caleiAccent)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Actualizar coordenadas en el ViewModel
    
    private func updateViewModelCoordinates() {
        switch locationMode {
        case .currentLocation:
            viewModel.useCurrentLocation = true
            
        case .mapSelection:
            viewModel.useCurrentLocation = false
            if let coordinate = selectedMapCoordinate {
                viewModel.manualLatitude = String(coordinate.latitude)
                viewModel.manualLongitude = String(coordinate.longitude)
            }
        }
    }
}

// MARK: - Map Point Selector View

struct MapPointSelectorView: View {
    let initialCoordinate: CLLocationCoordinate2D?
    let onSelect: (CLLocationCoordinate2D) -> Void
    let onCancel: () -> Void
    
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition
    
    let caleiAccent = Color(red: 0.310, green: 0.820, blue: 0.773)
    let caleiDark = Color(red: 0.118, green: 0.145, blue: 0.188)
    
    init(initialCoordinate: CLLocationCoordinate2D?, onSelect: @escaping (CLLocationCoordinate2D) -> Void, onCancel: @escaping () -> Void) {
        self.initialCoordinate = initialCoordinate
        self.onSelect = onSelect
        self.onCancel = onCancel
        
        // Inicializar la cámara
        let center = initialCoordinate ?? CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816) // Buenos Aires por defecto
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
        _selectedCoordinate = State(initialValue: initialCoordinate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Mapa con tap gesture
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        // Marcador del punto seleccionado
                        if let coordinate = selectedCoordinate {
                            Annotation("Punto seleccionado", coordinate: coordinate) {
                                VStack(spacing: 0) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(caleiAccent)
                                    
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(caleiAccent)
                                        .offset(y: -3)
                                }
                            }
                        }
                    }
                    .mapStyle(.standard)
                    .onTapGesture { screenCoordinate in
                        if let coordinate = proxy.convert(screenCoordinate, from: .local) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedCoordinate = coordinate
                            }
                        }
                    }
                }
                
                // Instrucciones
                VStack {
                    // Banner de instrucciones
                    HStack {
                        Image(systemName: "hand.tap")
                            .foregroundColor(caleiAccent)
                        Text("Toca el mapa para seleccionar el punto")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Coordenadas seleccionadas
                    if let coordinate = selectedCoordinate {
                        VStack(spacing: 8) {
                            Text("Coordenadas seleccionadas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(coordinate.latitude, specifier: "%.6f"), \(coordinate.longitude, specifier: "%.6f")")
                                .font(.footnote.monospaced())
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Seleccionar ubicación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirmar") {
                        if let coordinate = selectedCoordinate {
                            onSelect(coordinate)
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(caleiAccent)
                    .disabled(selectedCoordinate == nil)
                }
            }
        }
    }
}

#Preview {
    AddSalePointView(trackId: 1)
}
