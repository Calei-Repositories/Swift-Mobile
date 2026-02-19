import SwiftUI
import MapKit
import CoreLocation

struct MarkNewSalePointView: View {
    let deliveryId: Int
    @StateObject private var viewModel = MarkPointViewModel()
    @StateObject private var locationService = LocationService.shared
    
    @State private var locationMode: LocationMode = .currentLocation
    @State private var showMapSelector = false
    @State private var selectedMapCoordinate: CLLocationCoordinate2D?
    
    let caleiAccent = Color(red: 0.310, green: 0.820, blue: 0.773)
    let gray400 = Color(red: 0.580, green: 0.639, blue: 0.722)
    
    enum LocationMode: String, CaseIterable {
        case currentLocation = "Mi ubicación"
        case mapSelection = "Seleccionar en mapa"
    }

    var body: some View {
        Form {
            Section(header: Text("Información del punto")) {
                TextField("Nombre", text: $viewModel.name)
            }
            
            Section(header: Text("Ubicación")) {
                // Selector de modo
                Picker("Modo", selection: $locationMode) {
                    ForEach(LocationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                
                switch locationMode {
                case .currentLocation:
                    currentLocationView
                    
                case .mapSelection:
                    mapSelectionView
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error).foregroundColor(.red)
                }
            }

            if let success = viewModel.successMessage {
                Section {
                    Text(success).foregroundColor(.green)
                }
            }

            Section {
                Button {
                    updateCoordinatesAndSubmit()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Marcar punto")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                }
                .listRowBackground(caleiAccent)
                .disabled(viewModel.isLoading || !isFormValid)
            }
        }
        .navigationTitle("Nuevo punto")
        .fullScreenCover(isPresented: $showMapSelector) {
            MapPointSelectorView(
                initialCoordinate: selectedMapCoordinate ?? locationService.currentLocation?.coordinate,
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
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasValidLocation
    }
    
    private var hasValidLocation: Bool {
        switch locationMode {
        case .currentLocation:
            return locationService.currentLocation != nil
        case .mapSelection:
            return selectedMapCoordinate != nil
        }
    }
    
    // MARK: - Subviews
    
    private var currentLocationView: some View {
        Group {
            if let location = locationService.currentLocation {
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
    
    private var mapSelectionView: some View {
        VStack(spacing: 12) {
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
    
    // MARK: - Actions
    
    private func updateCoordinatesAndSubmit() {
        switch locationMode {
        case .currentLocation:
            if let location = locationService.currentLocation {
                viewModel.latitude = String(location.coordinate.latitude)
                viewModel.longitude = String(location.coordinate.longitude)
            }
            
        case .mapSelection:
            if let coordinate = selectedMapCoordinate {
                viewModel.latitude = String(coordinate.latitude)
                viewModel.longitude = String(coordinate.longitude)
            }
        }
        
        Task {
            await viewModel.submit(deliveryId: deliveryId)
        }
    }
}
