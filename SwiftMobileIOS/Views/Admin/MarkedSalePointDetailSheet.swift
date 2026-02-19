import SwiftUI

// MARK: - MarkedSalePointDetailSheet

struct MarkedSalePointDetailSheet: View {
    let salePoint: MarkedSalePoint
    let onSave: (UpdateSalePointRequest) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    // Campos editables
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var managerName: String = ""
    @State private var hasWhatsApp: Bool = false
    @State private var notes: String = ""
    @State private var openingHours: String = ""
    @State private var exhibitorType: String = ""
    @State private var status: String = "active"
    
    init(salePoint: MarkedSalePoint, onSave: @escaping (UpdateSalePointRequest) -> Void) {
        self.salePoint = salePoint
        self.onSave = onSave
        
        _name = State(initialValue: salePoint.name)
        _address = State(initialValue: salePoint.address ?? "")
        _phone = State(initialValue: salePoint.phone ?? "")
        _email = State(initialValue: salePoint.email ?? "")
        _managerName = State(initialValue: salePoint.managerName ?? "")
        _hasWhatsApp = State(initialValue: salePoint.hasWhatsApp ?? false)
        _notes = State(initialValue: salePoint.notes ?? "")
        _openingHours = State(initialValue: salePoint.openingHours ?? "")
        _exhibitorType = State(initialValue: salePoint.exhibitorType ?? "")
        _status = State(initialValue: salePoint.status ?? "active")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    basicInfoTab
                        .tag(0)
                    
                    contactTab
                        .tag(1)
                    
                    exhibitorTab
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Detalle del Punto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Básico", icon: "info.circle", index: 0)
            tabButton(title: "Contacto", icon: "phone", index: 1)
            tabButton(title: "Exhibidor", icon: "cube.box", index: 2)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption)
                    Text(title)
                        .font(.subheadline)
                }
                .foregroundColor(selectedTab == index ? CaleiColors.accent : CaleiColors.gray500)
                .fontWeight(selectedTab == index ? .semibold : .regular)
                
                Rectangle()
                    .fill(selectedTab == index ? CaleiColors.accent : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Basic Info Tab
    
    private var basicInfoTab: some View {
        Form {
            Section("Información General") {
                TextField("Nombre", text: $name)
                
                TextField("Dirección", text: $address)
                
                Picker("Estado", selection: $status) {
                    Text("Activo").tag("active")
                    Text("Inactivo").tag("inactive")
                    Text("Pendiente").tag("pending")
                }
            }
            
            Section("Ubicación") {
                HStack {
                    Text("Latitud")
                    Spacer()
                    Text(String(format: "%.6f", salePoint.latitude))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Longitud")
                    Spacer()
                    Text(String(format: "%.6f", salePoint.longitude))
                        .foregroundColor(.secondary)
                }
                
                if let zoneId = salePoint.zoneId {
                    HStack {
                        Text("Zona ID")
                        Spacer()
                        Text("\(zoneId)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Notas") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
    }
    
    // MARK: - Contact Tab
    
    private var contactTab: some View {
        Form {
            Section("Datos de Contacto") {
                TextField("Teléfono", text: $phone)
                    .keyboardType(.phonePad)
                
                Toggle(isOn: $hasWhatsApp) {
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundColor(.green)
                        Text("Tiene WhatsApp")
                    }
                }
                .tint(CaleiColors.accent)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section("Encargado") {
                TextField("Nombre del encargado", text: $managerName)
            }
            
            Section("Horario") {
                TextField("Horario de atención", text: $openingHours)
            }
        }
    }
    
    // MARK: - Exhibitor Tab
    
    private var exhibitorTab: some View {
        Form {
            Section("Tipo de Exhibidor") {
                Picker("Tipo", selection: $exhibitorType) {
                    Text("Sin exhibidor").tag("")
                    Text("Pequeño").tag("small")
                    Text("Mediano").tag("medium")
                    Text("Grande").tag("large")
                    Text("Refrigerador").tag("fridge")
                    Text("Góndola").tag("gondola")
                }
            }
            
            Section {
                exhibitorPreview
            } header: {
                Text("Vista Previa")
            }
        }
    }
    
    @ViewBuilder
    private var exhibitorPreview: some View {
        if exhibitorType.isEmpty {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "cube.box")
                        .font(.largeTitle)
                        .foregroundColor(CaleiColors.gray400)
                    Text("Sin exhibidor asignado")
                        .font(.subheadline)
                        .foregroundColor(CaleiColors.gray500)
                }
                Spacer()
            }
            .padding(.vertical, 20)
        } else {
            HStack(spacing: 12) {
                Image(systemName: exhibitorIcon)
                    .font(.title)
                    .foregroundColor(CaleiColors.accent)
                    .frame(width: 50, height: 50)
                    .background(CaleiColors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exhibitorLabel)
                        .font(.headline)
                    Text(exhibitorDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var exhibitorIcon: String {
        switch exhibitorType {
        case "small": return "cube.box"
        case "medium": return "shippingbox"
        case "large": return "shippingbox.fill"
        case "fridge": return "refrigerator"
        case "gondola": return "rectangle.split.3x3"
        default: return "cube.box"
        }
    }
    
    private var exhibitorLabel: String {
        switch exhibitorType {
        case "small": return "Exhibidor Pequeño"
        case "medium": return "Exhibidor Mediano"
        case "large": return "Exhibidor Grande"
        case "fridge": return "Refrigerador"
        case "gondola": return "Góndola"
        default: return "Desconocido"
        }
    }
    
    private var exhibitorDescription: String {
        switch exhibitorType {
        case "small": return "Capacidad reducida, ideal para espacios pequeños"
        case "medium": return "Capacidad estándar para la mayoría de tiendas"
        case "large": return "Alta capacidad para tiendas grandes"
        case "fridge": return "Para productos que requieren refrigeración"
        case "gondola": return "Exhibición en pasillo central"
        default: return ""
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        let request = UpdateSalePointRequest(
            name: name,
            description: nil,
            hasWhatsApp: hasWhatsApp,
            notes: notes.isEmpty ? nil : notes,
            competition: nil,
            status: status,
            managerName: managerName.isEmpty ? nil : managerName,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            openingTimeFrom: nil,
            openingTimeTo: nil,
            workingDays: nil,
            exhibitorType: exhibitorType.isEmpty ? nil : exhibitorType,
            supportType: nil,
            installationNotes: nil,
            address: address.isEmpty ? nil : address,
            openingHours: openingHours.isEmpty ? nil : openingHours
        )
        
        onSave(request)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    MarkedSalePointDetailSheet(
        salePoint: MarkedSalePoint(
            id: 1,
            name: "Tienda Ejemplo",
            latitude: 19.4326,
            longitude: -99.1332,
            zoneId: 1,
            address: "Calle Principal 123"
        ),
        onSave: { _ in }
    )
}
